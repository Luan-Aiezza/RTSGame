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
              let target = behaviorComponent.getCurrentEnemyTarget(),
              let unitPos = unit.component(ofType: GKSKNodeComponent.self)?.node.position,
              let enemyPos = target.component(ofType: GKSKNodeComponent.self)?.node.position else { return }
        
        // não ataca aliados
        guard let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              let unitTeam = unit.component(ofType: TeamComponent.self)?.team,
              targetTeam != unitTeam else { return }
        
        let dx = unitPos.x - enemyPos.x
        let dy = unitPos.y - enemyPos.y
        let distanceSquared = dx * dx + dy * dy

        // Alcance de ataque melee (dobrado)
        let attackRadius: CGFloat = 48

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
        // 1) Trigger the attack animation on the attacker, if available
        if let animationComp = unit.component(ofType: AnimationComponent.self) {
            animationComp.runAnimation(for: .attack)
        }
        
        // 1.1) Play melee attack sound effect (somente se visível pela câmera)
        if let node = unit.component(ofType: GKSKNodeComponent.self)?.node {
            AudioManager.shared.playSoundIfVisible(named: "Melee_Attack_Effect", from: node)
        }

        // 2) Apply damage to the target
        guard let health = target.component(ofType: HealthComponent.self) else { return }

        // Optional: target gets a small hit reaction if it supports it
        if let targetAnim = target.component(ofType: AnimationComponent.self) {
            targetAnim.runAnimation(for: .attack)
        }

        health.takeDamage(damage)

        // 3) Ensure death handling happens immediately for melee (no projectile to finalize the kill)
        if health.currentHealth <= 0 {
            // Try to call a `die()` helper if the entity provides it
            if let troop = target as? TroopEntity {
                troop.die()
            } else if let knight = target as? KnightTroopEntity {
                knight.die()
            } else {
                // Fallback: remove/destroy target entity when no typed die() exists
                if let node = target.component(ofType: GKSKNodeComponent.self)?.node {
                    node.removeAllActions()
                    node.removeFromParent()
                }
                target.destroy()

                // Força o behavior a reavaliar alvo
                if let behavior = unit.component(ofType: TroopBehaviorComponent.self) {
                    behavior.setTarget(nil) // limpa o congelado
                    behavior.configureBehavior()
                }

                // E força a stateMachine a voltar pro Idle, que já checa novo alvo
                unit.stateMachineComponent.stateMachine.enter(TroopIdleState.self)
            }
        }
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

