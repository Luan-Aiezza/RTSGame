//
//  UnitEntity.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 30/07/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

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


extension UnitEntity: AimingDelegate {
    func handleAim(direction: CGPoint, distance: CGFloat) {
        self.component(ofType: AimingComponent.self)
    }
}

extension GKEntity {
    /// Remove todos os componentes e referencia ao node
    func destroy() {
        if let node = self.component(ofType: GKSKNodeComponent.self)?.node {
            node.removeAllActions()
            node.removeAllChildren()
            node.removeFromParent()
        }
        // Remove todos os componentes ligados à entidade
        for component in self.components {
            self.removeComponent(ofType: type(of: component))
        }
    }
}
