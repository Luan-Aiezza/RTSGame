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
        
        var stringValue: String {
            switch self {
            case .idle:
                return "Idle_"
            case .walk:
                return "Walk_"
            case .attack:
                return "Attack_"
            case .die:
                return "Die_"
            case .custom(let name):
                return name
            }
        }
    }
    
    private let spriteNode: SKSpriteNode
    private var animations: [AnimationState: [SKTexture]] = [:]
    private(set) var currentState: AnimationState? = nil
    private var animationActions: [AnimationState: SKAction] = [:]

    public init(spriteNode: SKSpriteNode = SKSpriteNode()) {
        self.spriteNode = spriteNode
        super.init()
    }
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addAnimation(textures: [SKTexture], for state: AnimationState, timePerFrame: TimeInterval = 0.1, repeatForever: Bool = true) {
        animations[state] = textures
        let action = SKAction.animate(with: textures, timePerFrame: timePerFrame)
        animationActions[state] = repeatForever ? SKAction.repeatForever(action) : action
    }
    
    func setupTextures(name: String, quantity: Int, state: AnimationState) -> [SKTexture] {
        let textures = (1...quantity).map {
            print("\(name)\(state.stringValue)\($0)")
            return SKTexture(imageNamed: "\(name)\(state.stringValue)\($0)")
        }
        return textures
    }

    public func runAnimation(for state: AnimationState) {
        guard let action = animationActions[state], currentState != state else { return }
        spriteNode.removeAllActions()
        spriteNode.run(action, withKey: "animation")
        currentState = state
    }
    
    public var node: SKSpriteNode { spriteNode }
    
    public override func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        spriteNode.removeFromParent()
    }
    
    func configureAnimation(config: AnimationConfig) {
        for (animationState, frameTime) in config.actionAndTimePerFrame {
            
            let textures = setupTextures(name: config.assetName, quantity: config.assetQuantity[animationState] ?? 0, state: animationState)
            
            addAnimation(textures: textures, for: animationState, timePerFrame: frameTime)
            
        }
    }
}

struct AnimationConfig {
    let assetName: String
    let assetQuantity: [AnimationComponent.AnimationState: Int]
    let actionAndTimePerFrame: [AnimationComponent.AnimationState: TimeInterval]
}
