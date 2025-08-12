//
//  UnitEntity.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 30/07/25.
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

public class UnitEntity: GKEntity {
    private var stateMachineComponent: StateMachineComponent!

    public init(team: Team = .sun) {
        super.init()
        
        self.addComponent(AimingComponent())

        let spriteNode = SKSpriteNode(texture: nil, color: .clear, size: CGSize(width: 48, height: 48))
        self.addComponent(GKSKNodeComponent(node: spriteNode))

        // Criação das texturas
        let idleTextures = (1...24).map { SKTexture(imageNamed: "Sun_Hero_Idle_\($0)") }
        let walkTextures = (1...5).map { SKTexture(imageNamed: "Sun_Hero_Walk_\($0)") }

        // Componente de animação
        let animationComponent = AnimationComponent(spriteNode: spriteNode)
        animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
        animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        self.addComponent(animationComponent)

        // Estado e máquina de estados
        let idleState = IdleState(entity: self)
        let walkingState = WalkingState(entity: self)
        let stateMachine = GKStateMachine(states: [idleState, walkingState])
        self.stateMachineComponent = StateMachineComponent(stateMachine)
        self.addComponent(stateMachineComponent)

        self.addComponent(AimControlComponent(delegate: self))
        self.addComponent(ControlableComponent(delegate: self))
        self.addComponent(AdaptedControlableComponent(delegate: self))

        self.addComponent(MovementComponent(moveSpeed: 2))
        
        self.addComponent(TeamComponent(team: team)) // TeamComponent antes do HealthBarComponent para cor correta
        
        // Componente de Vida (padrão 100)
        let healthComponent = HealthComponent(maxHealth: 100)
        self.addComponent(healthComponent)
        
        let healthBar = HealthBarComponent()
        self.addComponent(healthBar)
        
        // Sincroniza barra com componente de vida
        healthComponent.onHealthChanged = { [weak healthBar] health, max in
            healthBar?.updateBar(health: health, max: max)
        }
        // Inicializa barra com valor cheio
        healthBar.updateBar(health: healthComponent.currentHealth, max: healthComponent.maxHealth)

        let rangeComponent = RangeComponent(radius: 120)
        self.addComponent(rangeComponent)
        
        // Adiciona AgentComponent para controlar movimentação via GKAgent2D e comportamentos
        let agent = AgentComponent(node: spriteNode)
        agent.agent.radius = 32
        agent.agent.maxSpeed = 100
        agent.agent.maxAcceleration = 300
        self.addComponent(agent)
    }
    
    var moveComponent: MovementComponent? {
        return self.component(ofType: MovementComponent.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension UnitEntity: ControlableDelegate {
    public func handleMovement(direction: CGPoint) {
        moveComponent?.change(direction: direction)
        
        let isMoving = direction != .zero
        if isMoving {
            stateMachineComponent.stateMachine.enter(WalkingState.self)
        } else {
            stateMachineComponent.stateMachine.enter(IdleState.self)
        }
    }
    
    public func handleButtonAPressed() {
        
    }
}

// Entidade de Tropa baseada em UnitEntity, sem controle manual do jogador
public class TroopEntity: UnitEntity {
    public override init(team: Team = .sun) {
        super.init(team: team)
        
        // 🔧 Ajusta o tamanho do sprite para 32x32
        if let spriteNode = self.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
            spriteNode.size = CGSize(width: 64, height: 64)
        }
        
        self.addComponent(TeamComponent(team: team)) // TeamComponent antes do HealthBarComponent para cor correta

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
            animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
            animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
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
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension UnitEntity: AimingDelegate {
    func handleAim(direction: CGPoint, distance: CGFloat) {
        self.component(ofType: AimingComponent.self)
    }
    
    
}
