// FlagEntity.swift
// Temporary entity for troop movement target
import SpriteKit
import GameplayKit

class FlagEntity: GKEntity {
    private let spriteNode: SKSpriteNode

    init(position: CGPoint) {
        self.spriteNode = SKSpriteNode(imageNamed: "Icon_1")
        self.spriteNode.position = position
        self.spriteNode.zPosition = 10000
        self.spriteNode.name = "flagEntity"
        self.spriteNode.setScale(0.8)
        super.init()
        self.addComponent(GKSKNodeComponent(node: spriteNode))
        // Optionally: Add a flicker or scale animation to make it visible
        let appear = SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.2),
            SKAction.scale(to: 0.8, duration: 0.15)
        ])
        spriteNode.run(appear)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var node: SKSpriteNode {
        return self.spriteNode
    }
}
