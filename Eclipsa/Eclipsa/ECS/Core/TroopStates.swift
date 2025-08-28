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
            agent.maxAcceleration = troop.component(ofType: AgentComponent.self)?.defaultMaxAcceleration ?? 120
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
              let range = troop.component(ofType: RangeComponent.self)?.radius,
              let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team else {
            return
        }
        
        // ❌ Não ataca aliados (ex: o herói do mesmo time)
        guard troopTeam != targetTeam else {
            // se o alvo for aliado, apenas segue (nunca entra em ataque)
            return
        }
        
        let d2 = (troopPos.x - targetPos.x) * (troopPos.x - targetPos.x) +
                 (troopPos.y - targetPos.y) * (troopPos.y - targetPos.y)
        
        if d2 <= range * range {
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
        
        _ = attack.tryAttack(on: target)
        attack.update(deltaTime: seconds)
    }
}

class TroopDieState: GKState {
    unowned let troop: BaseUnitEntity
    init(troop: BaseUnitEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .die)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.troop.destroy()
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool { false }
}

