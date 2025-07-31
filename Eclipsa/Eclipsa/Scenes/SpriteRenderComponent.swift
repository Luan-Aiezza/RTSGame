// SpriteRenderComponent.swift
import SpriteKit
import GameplayKit

/// Componente reutilizável para renderização de sprites
public class SpriteRenderComponent: GKComponent {
    public let spriteNode: SKSpriteNode

    /// Inicializa o componente com textura, cor, tamanho e zPosition opcionais
    public init(texture: SKTexture? = nil, color: SKColor = .clear, size: CGSize = .zero, zPosition: CGFloat = 0) {
        self.spriteNode = SKSpriteNode(texture: texture, color: color, size: size)
        self.spriteNode.zPosition = zPosition
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let spriteNode = coder.decodeObject(forKey: "spriteNode") as? SKSpriteNode else { return nil }
        self.spriteNode = spriteNode
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(spriteNode, forKey: "spriteNode")
    }

    public override func didAddToEntity() {
        super.didAddToEntity()
        // Adiciona o node ao parent se existir um componente de node
        if let nodeComponent = entity?.component(ofType: GKSKNodeComponent.self) {
            nodeComponent.node.addChild(spriteNode)
        }
    }

    public override func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        spriteNode.removeFromParent()
    }
}
