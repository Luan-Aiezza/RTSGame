import SpriteKit
import GameplayKit

/// Componente de range genérico para entidades
public class RangeComponent: GKComponent {
    public let radius: CGFloat
    public let color: SKColor
    public let node: SKShapeNode
//DEVOLVER O CIRCULO
    /// Handler chamado ao começar contato com um nó alvo
    public var didBeginContact: ((SKNode) -> Void)?
    /// Handler chamado ao terminar contato
    public var didEndContact: ((SKNode) -> Void)?

    public init(radius: CGFloat, color: SKColor = .cyan.withAlphaComponent(0.0)) {
        self.radius = radius
        self.color = color
        self.node = SKShapeNode(circleOfRadius: radius)
        super.init()
        node.fillColor = color
        node.lineWidth = 0
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
    }
    
    override public func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let nodeComponent = entity.component(ofType: GKSKNodeComponent.self),
              let scene = nodeComponent.node.scene else { return }
        let positionInScene = nodeComponent.node.convert(CGPoint.zero, to: scene)
        node.position = positionInScene
        if node.parent !== scene {
            scene.addChild(node)
        }
    }
    
    override public func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        node.removeFromParent()
    }
    public func resetColor() {
        node.fillColor = self.color
        node.strokeColor = self.color.withAlphaComponent(0.9)
    }
    
    /// Check if a given point is inside the range circle
    public func contains(point: CGPoint) -> Bool {
        guard node.scene != nil else { return false }
        let center = node.position
        let distance = hypot(point.x - center.x, point.y - center.y)
        return distance <= radius
    }
}

