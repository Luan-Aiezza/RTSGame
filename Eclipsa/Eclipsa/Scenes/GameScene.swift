import Foundation
import SpriteKit
import BehindGameKit
import GameplayKit
//import PhysicsBodyComponent
//import UInt32_PhysicsMasks

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    private var controlledEntity: UnitEntity!
    private var cameraEntity: CameraEntity!
    private var testBlockNode: SKSpriteNode?
    private var troopNode: SKSpriteNode?
    
    private var physicsSystem = PhysicsSystem()
    private var collisionSystem: CollisionSystem!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        setupVirtualController()
        
        controlledEntity = UnitEntity()
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
       
        if let camera = self.camera {
            cameraEntity = CameraEntity()
            cameraEntity.setupComponents(cameraNode: camera)
            cameraEntity.followPlayer(player: controlledEntity)
            SKEntityManager.shared.add(cameraEntity)
        }
        
        physicsSystem.setupHeroPhysics(for: controlledEntity)
        
        let block = physicsSystem.makeTestBlock(position: CGPoint(x: 200, y: 0))
        addChild(block)
        testBlockNode = block
        
        let troop = physicsSystem.makeTroop(position: CGPoint(x: -200, y: 0))
        addChild(troop)
        troopNode = troop
        
        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: testBlockNode)
        
        // Configura delegate de contato
        self.physicsWorld.contactDelegate = self
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if let moveComponent = controlledEntity.moveComponent {
            let isMoving = moveComponent.direction != .zero
            if let stateMachineComponent = controlledEntity.component(ofType: StateMachineComponent.self) {
                if isMoving {
                    stateMachineComponent.stateMachine.enter(WalkingState.self)
                } else {
                    stateMachineComponent.stateMachine.enter(IdleState.self)
                }
            }
        }
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
