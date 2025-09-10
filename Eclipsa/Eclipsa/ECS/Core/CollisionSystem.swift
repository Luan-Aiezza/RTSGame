import SpriteKit
import GameplayKit
import BehindGameKit

final class CollisionSystem {
    private weak var controlledEntity: UnitEntity?
    private weak var testBlockNode: SKSpriteNode?

    init(controlledEntity: UnitEntity?, testBlockNode: SKSpriteNode?) {
        self.controlledEntity = controlledEntity
        self.testBlockNode = testBlockNode
    }
    
    // MARK: - Public API
    func setControlledEntity(_ entity: UnitEntity?) {
        self.controlledEntity = entity
    }
    
    func clearControlledEntity() {
        self.controlledEntity = nil
    }
    
    func handleDidBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

        let rangeCategory = PhysicsCategory.range
        let troopCategory = PhysicsCategory.troop
        if (maskA == rangeCategory && maskB == troopCategory) || (maskB == rangeCategory && maskA == troopCategory) {
            if let rangeComponent = controlledEntity?.component(ofType: RangeComponent.self) {
                rangeComponent.setContactColor(.green.withAlphaComponent(0.25))
            }
        }

        if (maskA == PhysicsCategory.player && maskB == PhysicsCategory.wall) || (maskA == PhysicsCategory.wall && maskB == PhysicsCategory.player) {
            if let block = testBlockNode {
                block.color = .green
                block.run(.sequence([
                    .wait(forDuration: 0.2),
                    .run { [weak block] in block?.color = .red }
                ]))
            }
        }
    }

    func handleDidEnd(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask
        let rangeCategory = PhysicsCategory.range
        let troopCategory = PhysicsCategory.troop
        if (maskA == rangeCategory && maskB == troopCategory) || (maskB == rangeCategory && maskA == troopCategory) {
            if let rangeComponent = controlledEntity?.component(ofType: RangeComponent.self) {
                rangeComponent.resetColor()
            }
        }
    }
}

