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
    
}

