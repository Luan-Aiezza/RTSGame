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
        
        addNonControlableEntity()
        guard let somePoint = scene?.view?.frame.size else {return}
        let point = CGPoint(
            x: -somePoint.width/4,
            y: -somePoint.height/4)
        virtualController?.changePosition(point)
    }
    
    func addNonControlableEntity() {
        let unit1 = UnitEntity()
        let unit2 = UnitEntity()
        unit1.removeComponent(ofType: ControlableComponent.self)
        unit2.removeComponent(ofType: ControlableComponent.self)
        
        unit1.addComponent(FollowComponent(speed: 20))
        unit2.addComponent(FollowComponent(speed: 10))
        
        unit1.component(ofType: FollowComponent.self)?.target = controlledEntity
        unit2.component(ofType: FollowComponent.self)?.target = controlledEntity
        
        SKEntityManager.shared.add(unit1)
        SKEntityManager.shared.add(unit2)
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
    
    override func setupVirtualController() {
        virtualController = .init(scene: self, analogRadius: 25)
        virtualController?.setAnalogVisible(value: false)
    }
#if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        
        if location.x <= 0 {
//            virtualController?.setAnalogVisible(value: true)
//            virtualController?.changePosition(location)
            guard let somePoint = scene?.view?.frame.size else {return}
            let point = CGPoint(
                x: -somePoint.width/3,
                y: -somePoint.height/4)
            virtualController?.changePosition(point)
            virtualController?.touchBegan(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera,
                let location = touches.first?.location(in: camera),
              location.x <= 0 else { return }
        virtualController?.touchesEnded(touches, with: event)
//        virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera,
                let location = touches.first?.location(in: camera),
              location.x <= 0 else { return }
        virtualController?.touchesCancelled(touches, with: event)
//        virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
#endif
}

extension GameScene {
    func didBegin(_ contact: SKPhysicsContact) {
        collisionSystem.handleDidBegin(contact)
    }

    func didEnd(_ contact: SKPhysicsContact) {
        collisionSystem.handleDidEnd(contact)
    }
}
