import GameplayKit
import BehindGameKit

public class MeleeAttackComponent: GKComponent {
    private unowned let unit: BaseUnitEntity
    private var cooldown: TimeInterval
    private var lastAttackTime: TimeInterval = 0
    private var damage: Int
    
    public init(unit: BaseUnitEntity, damage: Int = 5, cooldown: TimeInterval = 3.0) {
        self.unit = unit
        self.damage = damage
        self.cooldown = cooldown
        super.init()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        guard let behaviorComponent = unit.component(ofType: TroopBehaviorComponent.self),
              let target = behaviorComponent.target as? BaseUnitEntity,
              let unitPos = unit.component(ofType: GKSKNodeComponent.self)?.node.position,
              let enemyPos = target.component(ofType: GKSKNodeComponent.self)?.node.position,
              let range = unit.component(ofType: RangeComponent.self)?.radius else { return }
        
        // não ataca aliados
        guard let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              let unitTeam = unit.component(ofType: TeamComponent.self)?.team,
              targetTeam != unitTeam else { return }
        
        let dx = unitPos.x - enemyPos.x
        let dy = unitPos.y - enemyPos.y
        let distanceSquared = dx * dx + dy * dy

        // Definindo uma distância mínima de ataque (melee precisa estar bem colado)
        let attackRadius: CGFloat = 32   // ajuste fino: pode testar 16~24

        if distanceSquared <= attackRadius * attackRadius {
            if CACurrentMediaTime() - lastAttackTime >= cooldown {
                performAttack(on: target)
                lastAttackTime = CACurrentMediaTime()
            }
        }
    }
    
    public func tryAttack(on target: BaseUnitEntity) -> Bool {
        guard let unitTeam = unit.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              unitTeam != targetTeam else { return false }
        
        if CACurrentMediaTime() - lastAttackTime >= cooldown {
            performAttack(on: target)
            lastAttackTime = CACurrentMediaTime()
            return true
        }
        return false
    }
    
    private func performAttack(on target: BaseUnitEntity) {
        // dispara animação de ataque
        if let animationComp = unit.component(ofType: AnimationComponent.self) {
            animationComp.runAnimation(for: .attack)
        }
        
        // aplica dano direto no alvo
        if let health = target.component(ofType: HealthComponent.self) {
            health.takeDamage(damage)
        }
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
