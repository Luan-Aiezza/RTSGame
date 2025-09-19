//
//  TroopStates.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 28/08/25.
//
import SpriteKit
import GameplayKit
import BehindGameKit

class TroopIdleState: GKState {
    unowned let troop: BaseUnitEntity
    init(troop: BaseUnitEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .idle)

        if let agent = troop.component(ofType: AgentComponent.self)?.agent {
            agent.maxSpeed = troop.component(ofType: AgentComponent.self)?.defaultMaxSpeed ?? 60
            agent.maxAcceleration = troop.component(ofType: AgentComponent.self)?.defaultMaxAcceleration ?? 60
            agent.behavior = GKBehavior()
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if let behavior = troop.component(ofType: TroopBehaviorComponent.self),
           behavior.getCurrentEnemyTarget() != nil {
            stateMachine?.enter(TroopFollowState.self)
        }
    }
}

class TroopFollowState: GKState {
    unowned let troop: BaseUnitEntity
    init(troop: BaseUnitEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .walk)
        
        if let agentComponent = troop.component(ofType: AgentComponent.self) {
            agentComponent.agent.maxSpeed = agentComponent.defaultMaxSpeed
            agentComponent.agent.maxAcceleration = agentComponent.defaultMaxAcceleration
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard let behavior = troop.component(ofType: TroopBehaviorComponent.self),
              let target = behavior.getCurrentEnemyTarget(),
              let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
              let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position,
              let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team else {
            return
        }
        
        // ❌ Não ataca aliados
        guard troopTeam != targetTeam else { return }
        
        let dx = troopPos.x - targetPos.x
        let dy = troopPos.y - targetPos.y
        let distanceSquared = dx * dx + dy * dy
        
        var attackThreshold: CGFloat
        
        if troop.component(ofType: MeleeAttackComponent.self) != nil {
            // ⚔️ melee: alcance maior para não precisar encostar
            attackThreshold = 64
        } else if let range = troop.component(ofType: RangeComponent.self)?.radius {
            // 🎯 ranged usa o range normal
            attackThreshold = range
        } else {
            attackThreshold = 64 // fallback
        }
        
        if distanceSquared <= attackThreshold * attackThreshold {
            stateMachine?.enter(TroopAttackState.self)
        } else if behavior.getCurrentEnemyTarget() == nil {
            stateMachine?.enter(TroopIdleState.self)
        }
    }

}

class TroopAttackState: GKState {
    unowned let troop: BaseUnitEntity
    init(troop: BaseUnitEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .attack)
        
        if let agent = troop.component(ofType: AgentComponent.self)?.agent {
            agent.maxSpeed = .zero
            agent.behavior = nil // <- limpa os goals
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // Aceita tanto ranged quanto melee como "attack component" ativo
        let attackComponent: GKComponent? =
            troop.component(ofType: AttackComponent.self) ??
            troop.component(ofType: MeleeAttackComponent.self)
        
        guard let behavior = troop.component(ofType: TroopBehaviorComponent.self),
              let target = behavior.getCurrentEnemyTarget(),
              let health = target.component(ofType: HealthComponent.self),
              let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              troopTeam != targetTeam,
              !health.isDead,
              attackComponent != nil else {
            // Sem alvo, alvo morto, aliado, ou sem componente de ataque -> sai do estado
            stateMachine?.enter(TroopIdleState.self)
            return
        }
        
        // Sai do estado de ataque se o alvo sair do alcance
        if let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
           let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position {
            let dx = troopPos.x - targetPos.x
            let dy = troopPos.y - targetPos.y
            let distanceSquared = dx * dx + dy * dy
            
            var attackThreshold: CGFloat
            if troop.component(ofType: MeleeAttackComponent.self) != nil {
                attackThreshold = 49
            } else if let range = troop.component(ofType: RangeComponent.self)?.radius {
                attackThreshold = range
            } else {
                attackThreshold = 49
            }
            
            if distanceSquared > attackThreshold * attackThreshold {
                // fora do alcance: voltar a perseguir
                stateMachine?.enter(TroopFollowState.self)
                return
            }
        }
        
        // Executa ataque (melee ou ranged)
        if let melee = attackComponent as? MeleeAttackComponent {
            _ = melee.tryAttack(on: target)
            melee.update(deltaTime: seconds)
        } else if let ranged = attackComponent as? AttackComponent {
            _ = ranged.tryAttack(on: target)
            ranged.update(deltaTime: seconds)
        }
    }
}

class TroopDieState: GKState {
    unowned let troop: BaseUnitEntity

    init(troop: BaseUnitEntity) { self.troop = troop }

    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .die)
        troop.component(ofType: TroopBehaviorComponent.self)?.invalidate()
        


        // toca o efeito sonoro de morte, se visível na câmera
        if let node = troop.component(ofType: GKSKNodeComponent.self)?.node {
            AudioManager.shared.playSoundIfVisible(named: "Unvoke_Effect", from: node)

            // remove nó visual após delay
            node.run(.sequence([
                .wait(forDuration: 0.7),
                .removeFromParent()
            ]))
        }
        // ❌ não chama remove nem destroy aqui
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool { false }
}
