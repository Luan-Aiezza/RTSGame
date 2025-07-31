import SpriteKit
import GameplayKit

/// Categoria de bitmask para o range
public struct PhysicsCategory {
    public static let range: UInt32 = 0x1 << 16
    public static let troop: UInt32 = 0x1 << 17
}

/// Componente de range genérico para entidades
public class RangeComponent: GKComponent {
    public let radius: CGFloat
    public let color: SKColor
    public let node: SKShapeNode

    /// Handler chamado ao começar contato com um nó alvo
    public var didBeginContact: ((SKNode) -> Void)?
    /// Handler chamado ao terminar contato
    public var didEndContact: ((SKNode) -> Void)?

    public init(radius: CGFloat, color: SKColor = .cyan.withAlphaComponent(0.25)) {
        self.radius = radius
        self.color = color
        self.node = SKShapeNode(circleOfRadius: radius)
        super.init()
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.9)
        node.lineWidth = 2
        node.zPosition = 100
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = false
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.range
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.troop
        node.physicsBody = body
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func didAddToEntity() {
        super.didAddToEntity()
        if let parent = entity?.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
            parent.addChild(node)
            node.position = .zero
        }
    }

    public func setContactColor(_ color: SKColor) {
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.9)
    }
    public func resetColor() {
        node.fillColor = self.color
        node.strokeColor = self.color.withAlphaComponent(0.9)
    }
}
