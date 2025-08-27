//
//  TroopEntity.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/08/25.
//
import SpriteKit
import GameplayKit
import BehindGameKit

// Entidade de Tropa baseada em BaseUnitEntity, sem controle manual do jogador
public class TroopEntity: BaseUnitEntity {
    public init(team: Team = .sun, allTroops: @escaping () -> [TroopEntity]) {
        
        
        // Texturas específicas da tropa (Mage)
        let idleTextures = (1...4).map { SKTexture(imageNamed: "Sun_Mage_Idle_\($0)") }
        let walkTextures = (1...4).map { SKTexture(imageNamed: "Sun_Mage_Walk_\($0)") }
        let spriteSize = CGSize(width: 32, height: 32)
        let maxHealth = 60
        
        super.init(team: team, maxHealth: maxHealth, spriteSize: spriteSize, idleTextures: idleTextures, walkTextures: walkTextures)
        
        // Ajusta animações adicionais: attack e death
        if let animationComponent = self.component(ofType: AnimationComponent.self) {
            let attackTextures = (1...4).map { SKTexture(imageNamed: "Sun_Mage_Casting_\($0)") }
            let deathTextures = (1...6).map { SKTexture(imageNamed: "Sun_Soldier_Death_\($0)") }
            
            animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.3, repeatForever: false)
            animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        }

        // Substituir a máquina anterior:
        let idle = TroopIdleState(troop: self)
        let follow = TroopFollowState(troop: self)
        let attack = TroopAttackState(troop: self)
        let die = TroopDieState(troop: self)

        let stateMachine = GKStateMachine(states: [idle, follow, attack, die])
        self.stateMachineComponent = StateMachineComponent(stateMachine)
        self.addComponent(stateMachineComponent)

        stateMachine.enter(TroopIdleState.self)
        
        // Componentes exclusivos da tropa
        if self.component(ofType: AttackComponent.self) == nil {
            self.addComponent(AttackComponent(troop: self, damage: 12, cooldown: 1.2))
        }
        
//        if self.component(ofType: TroopBehaviorComponent.self) == nil {
//            self.addComponent(TroopBehaviorComponent(
//                troop: self,
//                target: nil,
//                allTroops: allTroops
//            ))
//        }
        
        // Remove controle manual do jogador
        self.removeComponent(ofType: ControlableComponent.self)
        self.removeComponent(ofType: AdaptedControlableComponent.self)
        
        stateMachine.enter(TroopIdleState.self)
    }
    
    /// Command the troop to move to a given point, disabling any follow behavior.
    public func moveTo(point: CGPoint) {
        // Remove follow behavior if present
        self.removeComponent(ofType: TroopBehaviorComponent.self)
        // Move to the destination
        if let agentComponent = self.component(ofType: AgentComponent.self) {
            // Crie um agente alvo fixo na posição desejada
            let targetAgent = GKAgent2D()
            targetAgent.position = vector_float2(Float(point.x), Float(point.y))
            targetAgent.radius = 2.0 // Raio pequeno só para evitar colisões
            targetAgent.maxSpeed = agentComponent.agent.maxSpeed
            targetAgent.maxAcceleration = agentComponent.agent.maxAcceleration
            
            let goal = GKGoal(toSeekAgent: targetAgent)
            let behavior = GKBehavior(goal: goal, weight: 1.0)
            agentComponent.agent.behavior = behavior
        }
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

extension TroopEntity {
    public func die() {
        if let anim = self.component(ofType: AnimationComponent.self) {
            anim.runAnimation(for: .die)
        }
        
        // espera a animação terminar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.destroy()
        }
    }
    static func createTroop(at position: CGPoint, team: Team, troops: [TroopEntity]) -> TroopEntity {
        let troop = TroopEntity(team: team){
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

