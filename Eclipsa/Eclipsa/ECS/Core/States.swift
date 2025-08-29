//
//  States.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/08/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

class IdleState: GKState {
    unowned let entity: GKEntity
    init(entity: GKEntity) { self.entity = entity }
    override func didEnter(from previousState: GKState?) {
        (entity.component(ofType: AnimationComponent.self))?.runAnimation(for: .idle)
    }
}

class WalkingState: GKState {
    unowned let entity: GKEntity
    init(entity: GKEntity) { self.entity = entity }
    override func didEnter(from previousState: GKState?) {
        (entity.component(ofType: AnimationComponent.self))?.runAnimation(for: .walk)
    }
}

class DieState: GKState {
    unowned let entity: GKEntity
    init(entity: GKEntity) { self.entity = entity }
    
    override func didEnter(from previousState: GKState?) {
        entity.component(ofType: AnimationComponent.self)?.runAnimation(for: .die)

        if let node = entity.component(ofType: GKSKNodeComponent.self)?.node {
            let duration = entity.component(ofType: AnimationComponent.self)?
                .node
                .action(forKey: "animation")?
                .duration ?? 0.5
            
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: duration),
                SKAction.removeFromParent()
            ])) { [weak self] in
                print("entrei no remove From Parent")
                guard let entity = self?.entity else { return }
                for component in entity.components {
                    entity.removeComponent(ofType: type(of: component))
                }
                SKEntityManager.shared.remove(entity)
            }
        }
    }
}


class TroopIdleState: GKState {
    unowned let troop: TroopEntity
    init(troop: TroopEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .idle)

        if let agent = troop.component(ofType: AgentComponent.self)?.agent {
            agent.maxSpeed = troop.component(ofType: AgentComponent.self)?.defaultMaxSpeed ?? 60
            agent.maxAcceleration = troop.component(ofType: AgentComponent.self)?.defaultMaxAcceleration ?? 120
            // um behavior vazio mantém o agente "vivo"
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
    unowned let troop: TroopEntity
    init(troop: TroopEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .walk)
        
        if let agentComponent = troop.component(ofType: AgentComponent.self) {
            agentComponent.agent.maxSpeed = agentComponent.defaultMaxSpeed
            agentComponent.agent.maxAcceleration = agentComponent.defaultMaxAcceleration
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard let behavior = troop.component(ofType: TroopBehaviorComponent.self),
              let target = behavior.target as? TroopEntity,
              let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
              let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position,
              let range = troop.component(ofType: RangeComponent.self)?.radius else { return }
        
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
    unowned let troop: TroopEntity
    init(troop: TroopEntity) { self.troop = troop }
    
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
              let target = behavior.target as? TroopEntity,
              let health = target.component(ofType: HealthComponent.self),
              !health.isDead else {
            stateMachine?.enter(TroopIdleState.self)
            return
        }
        _ = attack.tryAttack(on: target)
        attack.update(deltaTime: seconds) // aplica dano se cooldown passou
    }
}

class TroopDieState: GKState {
    unowned let troop: TroopEntity
    init(troop: TroopEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .die)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.troop.destroy()
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool { false }
}
