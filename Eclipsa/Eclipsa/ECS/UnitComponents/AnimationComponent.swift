import SpriteKit
import GameplayKit

/// Componente reutilizável para animações frame a frame via SKTexture
public class AnimationComponent: GKComponent {
    public enum AnimationState: Hashable {
        case idle
        case walk
        case attack
        case die
        case custom(String)
    }
    
    private let spriteNode: SKSpriteNode
    private var animations: [AnimationState: [SKTexture]] = [:]
    private(set) var currentState: AnimationState? = nil
    private var animationActions: [AnimationState: SKAction] = [:]

    public init(spriteNode: SKSpriteNode = SKSpriteNode()) {
        self.spriteNode = spriteNode
        super.init()
    }
    
    public func addAnimation(textures: [SKTexture], for state: AnimationState, timePerFrame: TimeInterval = 0.1, repeatForever: Bool = true) {
        animations[state] = textures
        let action = SKAction.animate(with: textures, timePerFrame: timePerFrame)
        animationActions[state] = repeatForever ? SKAction.repeatForever(action) : action
    }

    public func runAnimation(for state: AnimationState) {
        guard let action = animationActions[state], currentState != state else { return }
        spriteNode.removeAllActions()
        spriteNode.run(action, withKey: "animation")
        currentState = state
    }
    
    public var node: SKSpriteNode { spriteNode }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        spriteNode.removeFromParent()
    }
}
