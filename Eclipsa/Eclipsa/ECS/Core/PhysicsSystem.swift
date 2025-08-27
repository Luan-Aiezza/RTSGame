import SpriteKit
import GameplayKit
import BehindGameKit

struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let ground: UInt32 = 0x1 << 1
    static let wall: UInt32 = 0x1 << 2
    static let troop: UInt32 = 0x1 << 3
    static let range: UInt32 = 0x1 << 4
}

extension UInt32 {
    static func contactWithAllCategories() -> UInt32 {
        return PhysicsCategory.player | PhysicsCategory.wall | PhysicsCategory.troop | PhysicsCategory.range
    }
}

final class PhysicsSystem {
    static let offset = CGPoint(x: 0, y: -10)
    
    // Configura o corpo físico do herói
    func setupHeroPhysics(for entity: UnitEntity) {
        if let nodeComponent = entity.component(ofType: GKSKNodeComponent.self),
           nodeComponent.node.physicsBody == nil {
            let heroBody = SKPhysicsBody(
                rectangleOf: CGSize(width: 32, height: 8),
                center: CGPoint(x: 0, y: -20) // desloca para baixo
            )
            heroBody.affectedByGravity = false
            heroBody.allowsRotation = false
            heroBody.categoryBitMask = PhysicsCategory.player
            heroBody.collisionBitMask = PhysicsCategory.wall
            heroBody.contactTestBitMask = UInt32.contactWithAllCategories()
            let heroPhysics = SKPhysicsBodyComponent(physicsBody: heroBody)
            entity.addComponent(heroPhysics)
        }
    }

    static func setupTroopPhysics(for entity: BaseUnitEntity) {
        if let nodeComponent = entity.component(ofType: GKSKNodeComponent.self),
           nodeComponent.node.physicsBody == nil {
            let troopBody = SKPhysicsBody(
                rectangleOf: CGSize(width: 48, height: 8),
                center: CGPoint(x: 0, y: -26) // desloca para baixo
            )
            troopBody.affectedByGravity = false
            troopBody.allowsRotation = false
            troopBody.categoryBitMask = PhysicsCategory.troop
            troopBody.collisionBitMask = PhysicsCategory.wall
            troopBody.contactTestBitMask = PhysicsCategory.range
            let troopPhysics = SKPhysicsBodyComponent(physicsBody: troopBody)
            entity.addComponent(troopPhysics)
        }
    }

    // Cria bloco de teste já com corpo físico
    func makeTestBlock(position: CGPoint) -> SKSpriteNode {
        let block = SKSpriteNode(color: .red, size: CGSize(width: 80, height: 40))
        block.position = position
        let blockBody = SKPhysicsBody(rectangleOf: block.size)
        blockBody.isDynamic = false
        blockBody.categoryBitMask = PhysicsCategory.wall
        blockBody.collisionBitMask = PhysicsCategory.player
        blockBody.contactTestBitMask = PhysicsCategory.player
        block.physicsBody = blockBody
        return block
    }
}

