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
                guard let entity = self?.entity else { return }
                for component in entity.components {
                    entity.removeComponent(ofType: type(of: component))
                }
            }
        }
    }
}


class TroopIdleState: GKState {
    unowned let troop: TroopEntity
    init(troop: TroopEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .idle)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // Se tiver alvo válido, troca para follow
        if let behavior = troop.component(ofType: TroopBehaviorComponent.self), behavior.target != nil {
            stateMachine?.enter(TroopFollowState.self)
        }
    }
}

class TroopFollowState: GKState {
    unowned let troop: TroopEntity
    init(troop: TroopEntity) { self.troop = troop }
    
    override func didEnter(from previousState: GKState?) {
        troop.component(ofType: AnimationComponent.self)?.runAnimation(for: .walk)
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
