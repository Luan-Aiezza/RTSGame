//
//  KnightTroopEntity.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 27/08/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

/// Entidade de Tropa Cavaleiro (melee), baseada em BaseUnitEntity
public class KnightTroopEntity: BaseUnitEntity {
    public init(team: Team = .sun, allTroops: @escaping () -> [TroopEntity]) {
        
        // Assets de animação específicos do Cavaleiro
        let idleTextures = (1...12).map { SKTexture(imageNamed: "Sun_Soldier_Idle_\($0)") }
        let walkTextures = (1...8).map { SKTexture(imageNamed: "Sun_Soldier_Walk_\($0)") }
        let spriteSize = CGSize(width: 32, height: 32)
        let maxHealth = 100   // mais vida que o mago
        
        super.init(team: team,
                   maxHealth: maxHealth,
                   spriteSize: spriteSize,
                   idleTextures: idleTextures,
                   walkTextures: walkTextures)
        
        // Ajusta animações adicionais: ataque corpo a corpo e morte
        if let animationComponent = self.component(ofType: AnimationComponent.self) {
            let attackTextures = (1...12).map { SKTexture(imageNamed: "Sun_Soldier_Attack_\($0)") }
            let deathTextures = (1...12).map { SKTexture(imageNamed: "Soldier_Sun_Dead_\($0)") }
            
            animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.05, repeatForever: true)
            animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        }
        
        // Máquina de estados
        let idle = TroopIdleState(troop: self)
        let follow = TroopFollowState(troop: self)
        let attack = TroopAttackState(troop: self)
        let die = TroopDieState(troop: self)
        
        let stateMachine = GKStateMachine(states: [idle, follow, attack, die])
        self.stateMachineComponent = StateMachineComponent(stateMachine)
        self.addComponent(stateMachineComponent)
        
        // Componente de ataque corpo a corpo
        if self.component(ofType: MeleeAttackComponent.self) == nil {
            self.addComponent(MeleeAttackComponent(unit: self, damage: 25, cooldown: 1.0))
        }
        
        // Ajusta o range para combate corpo a corpo
        if let rangeComp = self.component(ofType: RangeComponent.self) {
            rangeComp.node.path = CGPath(ellipseIn: CGRect(x: -16, y: -16, width: 32, height: 32), transform: nil)
            rangeComp.node.physicsBody = SKPhysicsBody(circleOfRadius: 16) // range bem menor
            rangeComp.node.physicsBody?.isDynamic = false
            rangeComp.node.physicsBody?.affectedByGravity = false
            rangeComp.node.physicsBody?.categoryBitMask = PhysicsCategory.range
            rangeComp.node.physicsBody?.collisionBitMask = 0
            rangeComp.node.physicsBody?.contactTestBitMask = PhysicsCategory.troop
        }
        
        // Remove controle manual
        self.removeComponent(ofType: ControlableComponent.self)
        self.removeComponent(ofType: AdaptedControlableComponent.self)
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        stateMachineComponent.stateMachine.update(deltaTime: seconds)
        
        // Flip horizontal baseado na velocidade do agent
        if let agentComponent = self.component(ofType: AgentComponent.self),
           let node = self.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
            
            let velocity = agentComponent.agent.velocity
            if velocity.x > 0 {
                node.xScale = abs(node.xScale)
            } else if velocity.x < 0 {
                node.xScale = -abs(node.xScale)
            }
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension KnightTroopEntity {
    public func die() {
        // Unifica o fluxo de morte via máquina de estados.
        // Se já estiver morto ou sem state machine, não faz nada.
        if let sm = stateMachineComponent?.stateMachine,
           !(sm.currentState is TroopDieState) {
            sm.enter(TroopDieState.self)
        }
    }
    
    static func createTroop(at position: CGPoint, team: Team, troops: [TroopEntity]) -> KnightTroopEntity {
        let troop = KnightTroopEntity(team: team) {
            return troops
        }
        troop.component(ofType: GKSKNodeComponent.self)?.node.position = position
        PhysicsSystem.setupTroopPhysics(for: troop)
        
        if let rangeComp = troop.component(ofType: RangeComponent.self),
           let nodeComp = troop.component(ofType: GKSKNodeComponent.self) {
            let scene = nodeComp.node.scene
            let positionInScene = nodeComp.node.position
            rangeComp.node.position = positionInScene
            if rangeComp.node.parent !== scene {
                scene?.addChild(rangeComp.node)
            }
        }
        
        return troop
    }
}
