
import SpriteKit
import GameplayKit
import BehindGameKit

public class NexusEntity: BuildingEntity {
    public var onDestroyed: (() -> Void)?

    public init(node: SKSpriteNode, team: Team) {
        super.init(node: node, team: team, maxHealth: 2500)

        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            health.onHealthChanged = { [weak self] current, max in
                previousCallback?(current, max)
                if current <= 0 {
                    AudioManager.shared.playSoundIfVisible(named: "Unvoke_Effect", from: node)
                    self?.onDestroyed?()
                }
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

