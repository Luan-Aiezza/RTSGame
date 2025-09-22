import SpriteKit
import GameplayKit
import BehindGameKit

public class InhibitorEntity: BuildingEntity {
    
    public var onDestroyed: (() -> Void)?
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .sun, maxHealth: 1500)
        self.addComponent(ResourceGeneratorComponent(rate: 5, maxResourcePerGeneration: 1)) // AJUSTAR
        
        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            
            health.onHealthChanged = { [weak self] current, max in
                // mantém o comportamento antigo (ex: atualizar barra de vida)
                previousCallback?(current, max)
                
                if current <= 0 {
                    // som de destruição (se quiser usar)
//                    AudioManager.shared.playSoundIfVisible(named: "Unvoke_Effect", from: node)
                    // dispara o callback de destruição
                    self?.onDestroyed?()
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
