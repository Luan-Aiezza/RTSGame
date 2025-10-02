import Foundation
import Combine
import SpriteKit
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    
    public weak var pauseButtonDelegate: GameScenePauseDelegate?
    
    public var controlledEntity: UnitEntity!
    public var cameraEntity: CameraEntity!
    public var troopNode: SKSpriteNode?
    public var enemyNode: SKSpriteNode?

    var sceneManager: SceneManager?
    var commandController: AdaptedVirtualController?
    var commandInput = InputHandler()
    var gameController: AdaptedVirtualController?
    var aimingSystem: AimingSystem?

    private var wallNode: SKSpriteNode?

    var buttons: ButtonsSet!

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

    // Flag para evitar múltiplos respawns concorrentes
    private var isRespawningPlayer = false

    // Substituímos o label numérico por um componente de HUD com ícones
    private var resourceHUD: UIResourceComponent?
    private var cancellables = Set<AnyCancellable>()
    public var footprintManager: FootprintManager?

    // Novo: componente visual para geração de recurso nos Inhibitors
    private var solarGeneratorUI: UISolarGeneratorComponent?

    var sceneConfiguration: SceneConfiguration?

    override func sceneDidLoad() {
        super.sceneDidLoad()

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.customLastUpdateTime = nil
        }

        applyNearestFilterRecursively()

        setupTreeCollisionsBorder(forTilemapNamed: "Tree_2")
        setupTreeCollisions(forTilemapNamed: "Tree_1")

        setupVirtualController() // precisa vir ANTES do player
        
        commandController = .init(scene: self, analogRadius: 50, color: .systemRed)
        
        commandController?.setAnalogVisible(value: false)
        
        let analogPosition = CGPoint(x: size.width/2 - 80, y: -size.height/2 + 180)
        commandController?.changePosition(CGPoint(x: size.width/2 - 80, y: -size.height/2 + 180))
        commandInput.observeGameController()
        
        // --- Círculo vermelho de fundo ---
        let haloNode = SKShapeNode(circleOfRadius: 50)
        haloNode.fillColor = .red
        haloNode.strokeColor = .clear
        haloNode.alpha = 0.20
        haloNode.zPosition = 998 // um a menos que o analogNode (que está em 999)
        haloNode.position = analogPosition

        camera?.addChild(haloNode) // adiciona atrás na câmera

        setupPlayer() //Instancia o player na cena
        // Observa a morte do player atual para respawn
        observePlayerDeath()

        setupCamera() //Instancia a camera na cena
        setupUI()
        setupSnow() // Intancia as particulas de neve
        buttons = .init(scene: self)
        
        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: nil)
        physicsWorld.contactDelegate = self

        // HUD de recursos (ícones)
        if let camera = self.camera {
            let hud = UIResourceComponent(scene: self, camera: camera)
            camera.addChild(hud)
            resourceHUD = hud
        }

        // Componente visual de geração dos Inhibitors
        let solarUI = UISolarGeneratorComponent()
        addChild(solarUI) // na cena (efeito é no mundo, não na câmera)
        solarGeneratorUI = solarUI
        
        // --- checagem por nome da cena ---
        if self.name == "GameScene_1" {
            // Tutorial
            //removeWizardButton()
            buttons.invokeMeleeButton?.isHidden = true
        }
        // --- checagem por nome da cena ---
        if self.name == "GameScene_2" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.startDialogue2()
            }
        }
        
        // Tutorial
        if self.name == "GameScene_0" {
            AudioManager.shared.fadeInBackgroundMusic(named: "OST_InTutorial")
            buttons.invokeMeleeButton?.isHidden = true
            startDialogue()
            
        } else {
            // Outras fases normais
            showPhaseOverlayFromSceneName()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.hidePhaseOverlay()
                self?.pauseButtonDelegate?.showPauseButton()
            }
        }
        
    }
    override func update(_ currentTime: TimeInterval) {
        // --- Protege contra primeira chamada ou retorno do background ---
        guard let lastTime = customLastUpdateTime else {
            customLastUpdateTime = currentTime
            return
        }

        var deltaTime = currentTime - lastTime
        customLastUpdateTime = currentTime

        // --- Clampa o deltaTime para evitar saltos absurdos ---
        // ex: máximo 1/30 ≈ 0.033s (30 FPS)
        if deltaTime > 1.0 / 60.0 {
            deltaTime = 1.0 / 60.0
        }

        // --- Atualiza sistemas normalmente ---
        SKEntityManager.shared.update(deltaTime)

        footprintManager?.update(deltaTime: deltaTime, currentTime: currentTime)
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

        // Garante que o HUD se reposicione se a escala da câmera mudar (caso ocorra)
        resourceHUD?.handleCameraOrSceneChange()
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
        gameController = AdaptedVirtualController(scene: self, analogRadius: 50, color: .systemBlue)
        gameController?.changePosition(Position.gameController(size: size))
        gameController?.setAnalogVisible(value: true)
        controlledEntity.component(ofType: AdaptedControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: gameController)
    }
}
// MARK: - Respawn do Player
extension GameScene {
    // Observa o HealthComponent do player atual e agenda respawn quando morrer
    func observePlayerDeath() {
        guard let health = controlledEntity?.component(ofType: HealthComponent.self) else { return }
        let previousHandler = health.onHealthChanged
        health.onHealthChanged = { [weak self, weak health] current, max in
            previousHandler?(current, max)
            guard let self = self, let health = health else { return }
            if health.isDead {
                self.schedulePlayerRespawn()
            }
        }
    }

    private func schedulePlayerRespawn() {
        guard !isRespawningPlayer else { return }
        isRespawningPlayer = true
        cleanupDeadPlayer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.respawnPlayer()
        }
    }

    private func cleanupDeadPlayer() {
        collisionSystem?.clearControlledEntity()
        if let dead = controlledEntity {
            SKEntityManager.shared.remove(dead)
        }
        controlledEntity?.destroy()
        aimingSystem?.player = nil
        troopControlSystem?.clearTargetEntity()
        cameraEntity?.followPlayer(player: nil)
        controlledEntity = nil
    }

    private func respawnPlayer() {
        setupPlayer()
        observePlayerDeath()
        collisionSystem?.setControlledEntity(controlledEntity)
        cameraEntity?.followPlayer(player: controlledEntity)
        troopControlSystem?.setTargetEntity(controlledEntity)
        aimingSystem?.player = controlledEntity
        isRespawningPlayer = false
    }
}
