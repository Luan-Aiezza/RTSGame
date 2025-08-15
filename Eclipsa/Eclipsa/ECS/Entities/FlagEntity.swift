// FlagEntity.swift
import SpriteKit
import GameplayKit

public class FlagEntity: GKEntity {
    public let spriteNode: SKSpriteNode
    public init(position: CGPoint) {
        let texture = SKTexture(imageNamed: "Icon_1")
        self.spriteNode = SKSpriteNode(texture: texture, color: .clear, size: texture.size())
        self.spriteNode.position = position
        self.spriteNode.zPosition = 1
        self.spriteNode.name = "FlagEntity"
        self.spriteNode.setScale(0.8)
        super.init()
        self.addComponent(GKSKNodeComponent(node: self.spriteNode))
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
