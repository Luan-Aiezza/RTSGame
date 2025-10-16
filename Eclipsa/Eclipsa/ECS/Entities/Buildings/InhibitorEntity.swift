import SpriteKit
import GameplayKit
import BehindGameKit

public class InhibitorEntity: BuildingEntity {
    public var onDestroyed: (() -> Void)?
    public var onRespawned: (() -> Void)?
    
    private let originalNode: SKSpriteNode
    private let respawnDelay: TimeInterval

    init(node: SKSpriteNode, team: Team, respawnDelay: TimeInterval, scene: GameScene) {
        self.originalNode = node
        self.respawnDelay = respawnDelay
        
        super.init(node: node, team: team, maxHealth: 1500)

        self.addComponent(ResourceGeneratorComponent(rate: 5, maxResourcePerGeneration: 1))
        self.addComponent(RespawnComponent(respawnDelay: respawnDelay, nodeTemplate: node, scene: scene))

        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            health.onHealthChanged = { [weak self] current, max in
                previousCallback?(current, max)
                if current <= 0 {
                    self?.handleDestruction()
                }
            }
        }
        setupRespawnAnimation()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func handleDestruction() {
        onDestroyed?()
        removeComponent(ofType: IndicatorAttackComponent.self)
        removeComponent(ofType: ResourceGeneratorComponent.self)
        
        let node = component(ofType: GKSKNodeComponent.self)?.node
        node?.physicsBody = nil
        
        if let respawnComp = component(ofType: RespawnComponent.self) {
            respawnComp.startRespawnCountdown()
        }
        
        let healthBar = component(ofType: HealthBarComponent.self)
        healthBar?.hideHealthBar(true)
        
    }
    
    public func handleRespawn() {
        if let health = component(ofType: HealthComponent.self) {
            health.restoreFullHealth()
        }
        addComponent(IndicatorAttackComponent())
        addComponent(ResourceGeneratorComponent(rate: 5, maxResourcePerGeneration: 1))
        guard let node = component(ofType: GKSKNodeComponent.self)?.node else { return }
        PhysicsSystem.setupBuildingPhysics(for: self, size: node.nodeSize)
        let healthBar = component(ofType: HealthBarComponent.self)
        healthBar?.hideHealthBar(false)
        onRespawned?()
    }
    
    private func setupRespawnAnimation(){
        
        guard let animationComponent = self.component(ofType: AnimationComponent.self) else { return }
        
        var contactTextures = (1...12).map { SKTexture(imageNamed: "Building_Born_\($0)") }
        contactTextures.append(SKTexture(imageNamed: "tent"))
        animationComponent.addAnimation(
            textures: contactTextures,
            for: .custom("respawn"),
            timePerFrame: 0.06,
            repeatForever: false
        )
        
        
    }
}

