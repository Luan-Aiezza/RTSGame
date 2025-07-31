import Foundation
import SpriteKit
import BehindGameKit
import GameplayKit
//import PhysicsBodyComponent
//import UInt32_PhysicsMasks

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    private var controlledEntity: GKEntity!
    private var testBlockNode: SKSpriteNode?
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        setupVirtualController()
        
        controlledEntity = UnitEntity()
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)

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

        // Configura delegate de contato
        self.physicsWorld.contactDelegate = self
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if let controlledEntity = controlledEntity as? UnitEntity,
           let moveComponent = controlledEntity.moveComponent {
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
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

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
}
