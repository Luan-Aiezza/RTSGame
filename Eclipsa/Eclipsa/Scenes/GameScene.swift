import Foundation
import SpriteKit
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    public var controlledEntity: UnitEntity!
    public var cameraEntity: CameraEntity!
    public var troopNode: SKSpriteNode?
    public var enemyNode: SKSpriteNode?
    var commandController: VirtualController?
    var commandInput = InputHandler()
    private var wallNode: SKSpriteNode?
    
    var gameController: AdaptedVirtualController?
    private var aimingSystem: AimingSystem?
    private var touchHandler: RTSTouchHandler?
    
    private var physicsSystem = PhysicsSystem()
    private var collisionSystem: CollisionSystem!
    private var troopControlSystem: TroopControlSystem!
    // Lista de tropas para controle coletivo
    public var troops: [TroopEntity] = []
    
    public var troopControlButtons: TroopControlButtons!
    
    public var customLastUpdateTime: TimeInterval?
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        setupVirtualController() // precisa vir ANTES do player
        commandController = .init(scene: self, analogRadius: 25)
        commandController?.setAnalogVisible(value: false)
        commandInput.observeGameController()

        setupPlayer()
        setupCamera()
        setupRTSAiming()
        setupTroops()
        setupUI()

        let wall = physicsSystem.makeTestBlock(position: CGPoint(x: -200, y: 0))
        addChild(wall)
        wallNode = wall

        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: nil)
        physicsWorld.contactDelegate = self
    }


    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        controlledEntity?.update(deltaTime: deltaTime)
        troops.forEach { $0.update(deltaTime: deltaTime) }
        cameraEntity?.followPlayer(player: controlledEntity)
        cameraEntity?.update(deltaTime: deltaTime)
        controlledEntity.component(ofType: AgentComponent.self)?.agent.update(deltaTime: deltaTime)
        troops.forEach { $0.component(ofType: AgentComponent.self)?.agent.update(deltaTime: deltaTime) }
        updateTroopTargets()
        updatePlayerState()
        updateTroopState()
        depthSortNodes()
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
        self.aimingSystem = aimingSystem
        touchHandler = RTSTouchHandler(scene: self, aimingSystem: aimingSystem)
    }
}

extension GameScene {
    func setupAdatpedVirtualController() {
        gameController = AdaptedVirtualController(scene: self, analogRadius: 50)
        gameController?.setAnalogVisible(value: false)
        controlledEntity.component(ofType: AdaptedControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: gameController)
    }
}
