import Foundation
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
        
        setupPlayer()
        setupTroops()
        
        setupNexus()   // cria base do jogador
        setupInhibitors() // cria inibidores aliados
        
        setupCamera()
        setupUI()
        setupSnow()   // Efeito de neve
        buttons = .init(scene: self)
        
        sceneEntity = SceneEntity(scene: self)
        SKEntityManager.shared.add(sceneEntity)
        
        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: nil)
        physicsWorld.contactDelegate = self
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        SKEntityManager.shared.update(deltaTime) //Trocar para DeltaTime
        
        controlledEntity?.update(deltaTime: deltaTime)
        troops.forEach { $0.update(deltaTime: deltaTime) }
        cameraEntity?.followPlayer(player: controlledEntity)
        cameraEntity?.update(deltaTime: deltaTime)
        controlledEntity.component(ofType: AgentComponent.self)?.agent.update(deltaTime: deltaTime)
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
