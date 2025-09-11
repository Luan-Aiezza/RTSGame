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
           behavior.target != nil {
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
              let target = behavior.target as? BaseUnitEntity,
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
            // ⚔️ melee precisa encostar
            attackThreshold = 32   // pode ajustar: 16–24
        } else if let range = troop.component(ofType: RangeComponent.self)?.radius {
            // 🎯 ranged usa o range normal
            attackThreshold = range
        } else {
            attackThreshold = 32 // fallback
        }
        
        if distanceSquared <= attackThreshold * attackThreshold {
            stateMachine?.enter(TroopAttackState.self)
        } else if behavior.target == nil {
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
        guard let attack = troop.component(ofType: AttackComponent.self),
              let behavior = troop.component(ofType: TroopBehaviorComponent.self),
              let target = behavior.target as? BaseUnitEntity,
              let health = target.component(ofType: HealthComponent.self),
              let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              troopTeam != targetTeam,   // ✅ impede atacar aliados
              !health.isDead else {
            stateMachine?.enter(TroopIdleState.self)
            return
        }
        
        // Novo: sair do estado de ataque se o alvo sair do range (ou do alcance de melee)
        if let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
           let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position {
            let dx = troopPos.x - targetPos.x
            let dy = troopPos.y - targetPos.y
            let distanceSquared = dx * dx + dy * dy
            
            var attackThreshold: CGFloat
            if troop.component(ofType: MeleeAttackComponent.self) != nil {
                attackThreshold = 32
            } else if let range = troop.component(ofType: RangeComponent.self)?.radius {
                attackThreshold = range
            } else {
                attackThreshold = 32
            }
            
            if distanceSquared > attackThreshold * attackThreshold {
                // fora do alcance: voltar a perseguir
                stateMachine?.enter(TroopFollowState.self)
                return
            }
        }
        
        _ = attack.tryAttack(on: target)
        attack.update(deltaTime: seconds)
    }
}

class TroopDieState: GKState {
    unowned let troop: BaseUnitEntity

    init(troop: BaseUnitEntity) { self.troop = troop }

    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .die)
        troop.component(ofType: TroopBehaviorComponent.self)?.invalidate()

        // só cuida do nó visual
        if let node = troop.component(ofType: GKSKNodeComponent.self)?.node {
            node.run(.sequence([
                .wait(forDuration: 0.7),
                .removeFromParent()
            ]))
        }
        // ❌ não chama remove nem destroy aqui
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool { false }
}

