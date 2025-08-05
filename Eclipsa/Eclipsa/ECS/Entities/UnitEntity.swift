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

        let spriteNode = SKSpriteNode(texture: nil, color: .clear, size: CGSize(width: 64, height: 64))
        self.addComponent(GKSKNodeComponent(node: spriteNode))

        // Criação das texturas
        let idleTextures = (1...24).map { SKTexture(imageNamed: "Sun_Hero_Idle\($0)") }
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

        self.addComponent(MovementComponent(moveSpeed: 2))
        
        let rangeComponent = RangeComponent(radius: 120)
        self.addComponent(rangeComponent)

        self.addComponent(TeamComponent(team: team))
    }
    
    var moveComponent: MovementComponent? {
        return self.component(ofType: MovementComponent.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCameraComponent(cameraNode: SKCameraNode) {
        self.addComponent(CameraComponent(moveSpeed: 1, cameraNode: cameraNode))
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
        
        if self.component(ofType: MovementComponent.self) == nil {
            self.addComponent(MovementComponent(moveSpeed: 2))
        }
        
        // Troca as animações para as animações específicas da tropa
        if let animationComponent = self.component(ofType: AnimationComponent.self) {
            let idleTextures = (1...11).map { SKTexture(imageNamed: "Sun_Troop_Idle_\($0)") }
            let walkTextures = (1...7).map { SKTexture(imageNamed: "Sun_Troop_Walk_\($0)") }
            animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
            animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        }
        // Garante que a tropa começa em idle e já anima
        if let stateMachineComponent = self.component(ofType: StateMachineComponent.self) {
            stateMachineComponent.stateMachine.enter(IdleState.self)
        }
        self.removeComponent(ofType: ControlableComponent.self)
        // Adicione mais componentes ou lógica específica das tropas se necessário
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Ativa o follow ao herói
    public func startFollowing(_ target: UnitEntity, withSpeed speed: CGFloat = 2.0) {
        if self.component(ofType: FollowComponent.self) == nil {
            let follow = FollowComponent(speed: speed)
            follow.target = target
            self.addComponent(follow)
        } else {
            self.component(ofType: FollowComponent.self)?.target = target
        }
    }
    
    // Para de seguir
    public func stopFollowing() {
        self.removeComponent(ofType: FollowComponent.self)
    }
}

