import GameplayKit
import BehindGameKit

public class AttackComponent: GKComponent {
    private unowned let troop: TroopEntity
    private var cooldown: TimeInterval
    private var lastAttackTime: TimeInterval = 0
    private var damage: Int
    
    public init(troop: TroopEntity, damage: Int = 10, cooldown: TimeInterval = 1.5) {
        self.troop = troop
        self.damage = damage
        self.cooldown = cooldown
        super.init()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        guard let target = (troop.component(ofType: TroopBehaviorComponent.self)?.target as? TroopEntity),
              let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
              let enemyPos = target.component(ofType: GKSKNodeComponent.self)?.node.position,
              let range = troop.component(ofType: RangeComponent.self)?.radius else { return }
        
        let d2 = (troopPos.x - enemyPos.x) * (troopPos.x - enemyPos.x) + (troopPos.y - enemyPos.y) * (troopPos.y - enemyPos.y)
        
        // Se inimigo está em alcance
        if d2 <= range * range {
            // Atacar apenas se cooldown passou
            if CACurrentMediaTime() - lastAttackTime >= cooldown {
                performAttack(on: target)
                lastAttackTime = CACurrentMediaTime()
            }
        }
    }
    
    private func performAttack(on target: TroopEntity) {
        if let health = target.component(ofType: HealthComponent.self) {
            health.takeDamage(damage)
            
            if health.isDead {
                target.component(ofType: StateMachineComponent.self)?.stateMachine.enter(DieState.self)
            }
        }
        
        // Troca para estado de ataque (roda animação)
        troop.component(ofType: StateMachineComponent.self)?.stateMachine.enter(AttackState.self)
    }
    
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
