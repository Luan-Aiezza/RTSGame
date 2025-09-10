import Foundation
import Combine
import SpriteKit
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    public var controlledEntity: UnitEntity!
    public var cameraEntity: CameraEntity!
    public var troopNode: SKSpriteNode?
    public var enemyNode: SKSpriteNode?
    var commandController: AdaptedVirtualController?
    var commandInput = InputHandler()
    private var wallNode: SKSpriteNode?
    
    var buttons: ButtonsSet!
    
    var gameController: AdaptedVirtualController?
    var aimingSystem: AimingSystem?
    
    var physicsSystem = PhysicsSystem()
    private var collisionSystem: CollisionSystem!
    var troopControlSystem: TroopControlSystem!
    // Lista de tropas para controle coletivo
    //    public var troops: [TroopEntity] = []
    public var troops: Set<TroopEntity> {
        SKEntityManager.shared.getAllGameTroops()
    }
    
    public var cancelButton: CommandButton!
    public var releaseButton: CommandButton!
    
    public var customLastUpdateTime: TimeInterval?
    var sceneEntity: SceneEntity!
    
    // Flag para evitar múltiplos respawns concorrentes
    private var isRespawningPlayer = false
    
    private var resourceLabel: SKLabelNode!
    private var cancellables = Set<AnyCancellable>()
    
    private func setupBindings() {
        ResourceHandler.shared.$storedResources
            .receive(on: RunLoop.main) // garante atualização na main thread
            .sink { [weak self] newValue in
                self?.resourceLabel.text = "\(newValue)"
            }
            .store(in: &cancellables)
    }
    
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        applyNearestFilterRecursively()
        
        setupTreeCollisionsBorder(forTilemapNamed: "Tree_2")
        setupTreeCollisions(forTilemapNamed: "Tree_1")
        
        setupVirtualController() // precisa vir ANTES do player
        commandController = .init(scene: self, analogRadius: 50)
        commandController?.setAnalogVisible(value: false)
        commandController?.changePosition(CGPoint(x: size.width/2 - 80, y: -size.height/2 + 180))
        commandInput.observeGameController()
        
        setupPlayer() //Instancia o player na cena
        // Observa a morte do player atual para respawn
        observePlayerDeath()
        
        setupNexus()   // cria base do jogador
        setupInhibitors() // cria inibidores aliados
        
        setupCamera() //Instancia a camera na cena
        startDialogue() //Instancia os dialogos na cena
        setupUI()
        setupSnow() // Intancia as particulas de neve
        buttons = .init(scene: self)
        
        sceneEntity = SceneEntity(scene: self)
        SKEntityManager.shared.add(sceneEntity)
        
        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: nil)
        physicsWorld.contactDelegate = self
        
        resourceLabel = SKLabelNode(fontNamed: "Arial")
                resourceLabel.fontSize = 50
                resourceLabel.fontColor = .red
        resourceLabel.position = Position.resourceLabel(size: size)
        self.camera?.addChild(resourceLabel)
                
                setupBindings()
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        SKEntityManager.shared.update(deltaTime) //Trocar para DeltaTime
        
        controlledEntity?.update(deltaTime: deltaTime)
        troops.forEach { $0.update(deltaTime: deltaTime) }
        cameraEntity?.followPlayer(player: controlledEntity)
        cameraEntity?.update(deltaTime: deltaTime)
        // Protege quando o player não existe (janela de respawn)
        controlledEntity?.component(ofType: AgentComponent.self)?.agent.update(deltaTime: deltaTime)
        troops.forEach { $0.component(ofType: AgentComponent.self)?.agent.update(deltaTime: deltaTime) }
        
        if let projectiles = self.userData?["projectiles"] as? [ProjectileEntity] {
            for projectile in projectiles {
                projectile.update(deltaTime: deltaTime)
            }
        }
        
        updateTroopTargets()
        updatePlayerState()
        depthSortNodes()
        aimingSystem?.updateDynamicAiming()
        
    }
    
}

extension GameScene {
    func didBegin(_ contact: SKPhysicsContact) {
        collisionSystem.handleDidBegin(contact)
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        collisionSystem.handleDidEnd(contact)
    }
}

extension GameScene {
    func setupRTSAiming() {
        let aimingSystem = AimingSystem(scene: self)
        aimingSystem.player = controlledEntity
        
        if let player = controlledEntity{
            aimingSystem.addComponent(foundIn: player)
        }
        self.aimingSystem = aimingSystem
    }
}

extension GameScene {
    func setupAdatpedVirtualController() {
        gameController = AdaptedVirtualController(scene: self, analogRadius: 50)
        gameController?.setAnalogVisible(value: false)
        controlledEntity.component(ofType: AdaptedControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: gameController)
    }
}

// MARK: - Respawn do Player
extension GameScene {
    // Observa o HealthComponent do player atual e agenda respawn quando morrer
    func observePlayerDeath() {
        guard let health = controlledEntity?.component(ofType: HealthComponent.self) else { return }
        // Compor com o handler existente (ex.: da barra de vida)
        let previousHandler = health.onHealthChanged
        health.onHealthChanged = { [weak self, weak health] current, max in
            // 1) mantém a barra de vida funcionando
            previousHandler?(current, max)
            // 2) respawn
            guard let self = self, let health = health else { return }
            if health.isDead {
                self.schedulePlayerRespawn()
            }
        }
    }
    
    private func schedulePlayerRespawn() {
        guard !isRespawningPlayer else { return }
        isRespawningPlayer = true
        
        // Limpa dependências do player morto e deixa animações/DieState fazerem o ciclo de remoção do nó
        cleanupDeadPlayer()
        
        // Agenda respawn em 5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.respawnPlayer()
        }
    }
    
    private func cleanupDeadPlayer() {
        // Descadastra o player do collisionSystem e outros que mantêm referência
        collisionSystem?.clearControlledEntity()
        
        // Remove a entidade do EntityManager para evitar vazamento e updates
        if let dead = controlledEntity {
            SKEntityManager.shared.remove(dead)
        }
        
        // Opcional: destruir componentes remanescentes (DieState já remove node e componentes)
        controlledEntity?.destroy()
        
        // Desvincula sistemas que apontavam para o player antigo
        aimingSystem?.player = nil
        troopControlSystem?.clearTargetEntity()
        cameraEntity?.followPlayer(player: nil)
        
        // Zera referência
        controlledEntity = nil
    }
    
    private func respawnPlayer() {
        // Cria e configura um novo player usando o pipeline existente
        setupPlayer()
        // Reobservar morte do novo player
        observePlayerDeath()
        
        // Reaponta sistemas que dependem do player
        collisionSystem?.setControlledEntity(controlledEntity)
        cameraEntity?.followPlayer(player: controlledEntity)
        troopControlSystem?.setTargetEntity(controlledEntity)
        aimingSystem?.player = controlledEntity
        
        isRespawningPlayer = false
    }
}
