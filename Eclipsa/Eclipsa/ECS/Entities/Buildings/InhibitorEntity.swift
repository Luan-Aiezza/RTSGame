import SpriteKit
import GameplayKit
import BehindGameKit

public class InhibitorEntity: BuildingEntity {
    public var onDestroyed: (() -> Void)?

    public init(node: SKSpriteNode, team: Team) {
        super.init(node: node, team: team, maxHealth: 1500)

        self.addComponent(ResourceGeneratorComponent(rate: 5, maxResourcePerGeneration: 1))

        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            health.onHealthChanged = { [weak self] current, max in
                previousCallback?(current, max)
                if current <= 0 {
                    self?.onDestroyed?()
                }
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

