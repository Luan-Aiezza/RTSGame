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
    private weak var attackTarget: BaseUnitEntity?

    init(troop: BaseUnitEntity) { self.troop = troop }

    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .attack)

        if let agent = troop.component(ofType: AgentComponent.self)?.agent {
            agent.maxSpeed = .zero
            agent.behavior = nil
        }

        // Congela o alvo no momento da entrada
        if let target = troop.component(ofType: TroopBehaviorComponent.self)?.getCurrentEnemyTarget() {
            attackTarget = target
        }
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard
            let target = attackTarget, // usa alvo congelado
            let health = target.component(ofType: HealthComponent.self),
            let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
            let targetTeam = target.component(ofType: TeamComponent.self)?.team,
            troopTeam != targetTeam,
            !health.isDead
        else {
            // alvo morreu ou não é válido → sair
            stateMachine?.enter(TroopIdleState.self)
            return
        }

        // Confere distância antes de atacar
        if let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
           let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position {
            let dx = troopPos.x - targetPos.x
            let dy = troopPos.y - targetPos.y
            let distanceSquared = dx * dx + dy * dy

            var attackThreshold: CGFloat
            if troop.component(ofType: MeleeAttackComponent.self) != nil {
                attackThreshold = 48
            } else if let range = troop.component(ofType: RangeComponent.self)?.radius {
                attackThreshold = range
            } else {
                attackThreshold = 48
            }

            if distanceSquared > attackThreshold * attackThreshold {
                // alvo saiu do alcance → volta a perseguir
                stateMachine?.enter(TroopFollowState.self)
                return
            }
        }

        // Executa ataque
        if let melee = troop.component(ofType: MeleeAttackComponent.self) {
            _ = melee.tryAttack(on: target)
            melee.update(deltaTime: seconds)
        } else if let ranged = troop.component(ofType: AttackComponent.self) {
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
