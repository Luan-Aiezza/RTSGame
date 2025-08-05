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

        // Corpo físico do herói
        if let nodeComponent = controlledEntity.component(ofType: GKSKNodeComponent.self),
           nodeComponent.node.physicsBody == nil {
            let heroBody = SKPhysicsBody(rectangleOf: CGSize(width: 64, height: 64))
            heroBody.affectedByGravity = false
            heroBody.allowsRotation = false
            heroBody.categoryBitMask = .player
            heroBody.collisionBitMask = .ground | .wall
            heroBody.contactTestBitMask = UInt32.contactWithAllCategories()
            let heroPhysics = SKPhysicsBodyComponent(physicsBody: heroBody)
            controlledEntity.addComponent(heroPhysics)
        }

        // Bloco de teste
        let block = SKSpriteNode(color: .red, size: CGSize(width: 80, height: 40))
        block.position = CGPoint(x: 200, y: 0)
        let blockBody = SKPhysicsBody(rectangleOf: block.size)
        blockBody.isDynamic = false
        blockBody.categoryBitMask = .wall
        blockBody.collisionBitMask = .player
        blockBody.contactTestBitMask = .player
        block.physicsBody = blockBody
        addChild(block)
        testBlockNode = block
        
        let troop = SKSpriteNode(color: .blue, size: CGSize(width: 48, height: 48))
        troop.position = CGPoint(x: -200, y: 0)
        let troopBody = SKPhysicsBody(rectangleOf: troop.size)
        troopBody.isDynamic = true
        troopBody.affectedByGravity = false
        troopBody.categoryBitMask = PhysicsCategory.troop
        troopBody.collisionBitMask = 0
        troopBody.contactTestBitMask = PhysicsCategory.range
        troop.physicsBody = troopBody
        addChild(troop)
        // Store as property if needed for further use

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
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

        let rangeCategory = PhysicsCategory.range
        let troopCategory = PhysicsCategory.troop
        if (maskA == rangeCategory && maskB == troopCategory) || (maskB == rangeCategory && maskA == troopCategory) {
            // Get the range node
               if let rangeComponent = controlledEntity.component(ofType: RangeComponent.self) {
                rangeComponent.setContactColor(.green.withAlphaComponent(0.25))
            }
        }

        // Checa colisão entre player e bloco de teste
        if (maskA == .player && maskB == .wall) || (maskA == .wall && maskB == .player) {
            if let block = testBlockNode {
                block.color = .green
                block.run(.sequence([
                    .wait(forDuration: 0.2),
                    .run { [weak block] in block?.color = .red }
                ]))
            }
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let rangeCategory = PhysicsCategory.range
        let troopCategory = PhysicsCategory.troop
        if (maskA == rangeCategory && maskB == troopCategory) || (maskB == rangeCategory && maskA == troopCategory) {
            if let rangeComponent = controlledEntity.component(ofType: RangeComponent.self) {
                rangeComponent.resetColor()
            }
        }
    }
}
