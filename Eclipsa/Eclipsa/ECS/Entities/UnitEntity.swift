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

    public override init() {
        super.init()

        let spriteNode = SKSpriteNode(texture: nil, color: .clear, size: CGSize(width: 64, height: 64))
        self.addComponent(GKSKNodeComponent(node: spriteNode))

        // Criação das texturas
        let idleTextures = (1...11).map { SKTexture(imageNamed: "citizen_idle_\($0)") }
        let walkTextures = (1...8).map { SKTexture(imageNamed: "citizen_walk_\($0)") }

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
        self.addComponent(MovementComponent(moveSpeed: 2))
        
        let rangeComponent = RangeComponent(radius: 120)
        self.addComponent(rangeComponent)
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
