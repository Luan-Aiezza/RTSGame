//
//  MeleeAttackComponent.swift
//  Eclipsa
//
//  Criado para ataques corpo a corpo sem projétil
//

import GameplayKit
import SpriteKit
import BehindGameKit

public class MeleeAttackComponent: GKComponent {
    unowned let attacker: BaseUnitEntity
    private let damage: Int
    private let cooldown: TimeInterval
    
    private var lastAttackTime: TimeInterval = 0
    
    public init(attacker: BaseUnitEntity, damage: Int, cooldown: TimeInterval) {
        self.attacker = attacker
        self.damage = damage
        self.cooldown = cooldown
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public func tryAttack(target: BaseUnitEntity, currentTime: TimeInterval) {
        guard currentTime - lastAttackTime >= cooldown else { return }
        
        // pega distância real entre atacante e alvo
        guard let attackerPos = attacker.component(ofType: GKSKNodeComponent.self)?.node.position,
              let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position else { return }
        
        let distance = hypot(targetPos.x - attackerPos.x, targetPos.y - attackerPos.y)
        
        // considera alcance corpo a corpo (pode ajustar)
        if distance <= 40 {
            performAttack(on: target)
            lastAttackTime = currentTime
        }
    }
    
    private func performAttack(on target: BaseUnitEntity) {
        if let health = target.component(ofType: HealthComponent.self) {
            health.takeDamage(damage)
            
            // se for tropa, entra no DieState
            if health.isDead, let troop = target as? TroopEntity {
                troop.stateMachineComponent.stateMachine.enter(TroopDieState.self)
            }
        }
        
        // opcional: animação de ataque
        if let anim = attacker.component(ofType: AnimationComponent.self) {
            anim.runAnimation(for: .attack)
        }
    }
}
