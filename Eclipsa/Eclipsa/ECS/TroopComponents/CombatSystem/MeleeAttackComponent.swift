import GameplayKit
import BehindGameKit
import SpriteKit

public class MeleeAttackComponent: GKComponent {
    private unowned let unit: BaseUnitEntity
    private var cooldown: TimeInterval
    private var lastAttackTime: TimeInterval = 0
    private var damage: Int
    
    /// Alcance fixo para ataque melee
    private let attackRadius: CGFloat = 49.0
    
    public init(unit: BaseUnitEntity, damage: Int = 10, cooldown: TimeInterval = 1.2) {
        self.unit = unit
        self.damage = damage
        self.cooldown = cooldown
        super.init()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        guard let behavior = unit.component(ofType: TroopBehaviorComponent.self),
              let target = behavior.getCurrentEnemyTarget(),
              let unitNode = unit.component(ofType: GKSKNodeComponent.self)?.node,
              let targetNode = target.component(ofType: GKSKNodeComponent.self)?.node else { return }
        
        // ❌ nunca ataca aliados
        guard let unitTeam = unit.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              unitTeam != targetTeam else { return }
        
        let dx = unitNode.position.x - targetNode.position.x
        let dy = unitNode.position.y - targetNode.position.y
        let d2 = dx*dx + dy*dy
        
        if d2 <= attackRadius * attackRadius {
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
        // 1) animação + som
        if let anim = unit.component(ofType: AnimationComponent.self) {
            anim.runAnimation(for: .attack)
        }
        if let node = unit.component(ofType: GKSKNodeComponent.self)?.node {
            AudioManager.shared.playSoundIfVisible(named: "Melee_Attack_Effect", from: node)
        }
        
        // 2) aplica dano
        guard let health = target.component(ofType: HealthComponent.self) else { return }
        health.takeDamage(damage)
        
        // animação de impacto no alvo (se suportar)
        if let anim = target.component(ofType: AnimationComponent.self) {
            anim.runAnimation(for: .custom("hit"))
        }
        
        // 3) se morreu → dispara fluxo de morte
        if health.isDead {
            if let troop = target as? TroopEntity {
                troop.die()
            } else if let knight = target as? KnightTroopEntity {
                knight.die()
            } else {
                // fallback: limpa do jogo
                if let node = target.component(ofType: GKSKNodeComponent.self)?.node {
                    node.removeAllActions()
                    node.removeFromParent()
                }
                target.destroy()
            }
            
            // força comportamento a reavaliar alvo
            if let behavior = unit.component(ofType: TroopBehaviorComponent.self) {
                behavior.setTarget(nil)
                behavior.configureBehavior()
            }
            
            // força state machine para Idle
            unit.stateMachineComponent.stateMachine.enter(TroopIdleState.self)
        }
    }
    
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
