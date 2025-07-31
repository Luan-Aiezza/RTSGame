import SpriteKit
import GameplayKit
import BehindGameKit

class MovementComponent: GKComponent {
    var node: SKNode?
    var moveSpeed: CGFloat
    var direction: CGVector = .zero
    
    init(moveSpeed: CGFloat) {
        self.moveSpeed = moveSpeed
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didAddToEntity() {
        node = self.entity?.component(ofType: GKSKNodeComponent.self)?.node
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let velocity = self.direction.normalized() * moveSpeed
        
        node?.run(.move(by: velocity, duration: 0.1))
    }
    
    public func change(direction: CGPoint) {
        self.direction = .init(dx: direction.x,
                               dy: direction.y)
    }
}
