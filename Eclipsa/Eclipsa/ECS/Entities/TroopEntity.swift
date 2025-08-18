//
//  TroopEntity.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/08/25.
//
import SpriteKit
import GameplayKit
import BehindGameKit

// Entidade de Tropa baseada em UnitEntity, sem controle manual do jogador
public class TroopEntity: UnitEntity {
    public override init(team: Team = .sun) {
        super.init(team: team)
        
        // 🔧 Ajusta o tamanho do sprite para 32x32
        if let spriteNode = self.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
            spriteNode.size = CGSize(width: 64, height: 64)
        }
        
        self.addComponent(TeamComponent(team: team)) // TeamComponent antes do HealthBarComponent para cor correta

        if self.component(ofType: AttackComponent.self) == nil {
            self.addComponent(AttackComponent(troop: self, damage: 12, cooldown: 1.2))
        }
        
        // Garante componente de Vida e barra
        if self.component(ofType: HealthComponent.self) == nil {
            let healthComponent = HealthComponent(maxHealth: 60)
            self.addComponent(healthComponent)
            let healthBar = HealthBarComponent()
            self.addComponent(healthBar)
            healthComponent.onHealthChanged = { [weak healthBar] health, max in
                healthBar?.updateBar(health: health, max: max)
            }
            healthBar.updateBar(health: healthComponent.currentHealth, max: healthComponent.maxHealth)
        }
        
        if self.component(ofType: MovementComponent.self) == nil {
            self.addComponent(MovementComponent(moveSpeed: 2))
        }
        
        // Troca as animações para as animações específicas da tropa
        if let animationComponent = self.component(ofType: AnimationComponent.self) {
            let idleTextures = (1...12).map { SKTexture(imageNamed: "Sun_Soldier_Idle_\($0)") }
            let walkTextures = (1...8).map { SKTexture(imageNamed: "Sun_Soldier_Walk_\($0)") }
            let attackTextures = (1...3).map { SKTexture(imageNamed: "Sun_Soldier_Attack_\($0)") }
            let deathTextures = (1...6).map { SKTexture(imageNamed: "Sun_Soldier_Death_\($0)") }
            
            animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
            animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
            animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.08, repeatForever: false)
            animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        }
        // Garante que a tropa começa em idle e já anima
        if let stateMachineComponent = self.component(ofType: StateMachineComponent.self) {
            stateMachineComponent.stateMachine.enter(IdleState.self)
        }
        self.removeComponent(ofType: ControlableComponent.self)
        self.removeComponent(ofType: AdaptedControlableComponent.self)
        
        // Movimentação das tropas agora será feita via GKAgent2D e comportamentos (GKBehavior).
        // Comportamentos como seguir e evitar serão adicionados em etapas futuras.
        
        // Adiciona AgentComponent para controle de movimentação por IA
        if let node = self.component(ofType: AnimationComponent.self)?.node,
           self.component(ofType: AgentComponent.self) == nil {
            let agent = AgentComponent(node: node)
            agent.agent.radius = 32
            agent.agent.maxSpeed = 80
            agent.agent.maxAcceleration = 250
            self.addComponent(agent)
        }
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
}
