
import SpriteKit
import GameplayKit
import BehindGameKit

public class NexusEntity: BuildingEntity {
    
    public var onDestroyed: (() -> Void)?
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .sun, maxHealth: 2000)
        
        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            
            health.onHealthChanged = { [weak self] current, max in
                // mantém o comportamento antigo (ex: atualizar barra de vida)
                previousCallback?(current, max)
                
                // adiciona a condição de derrota do Nexus
                if current <= 0 {
                    self?.onDestroyed?()
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
