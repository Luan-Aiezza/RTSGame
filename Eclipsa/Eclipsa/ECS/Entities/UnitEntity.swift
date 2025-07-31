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

        // Componente de estado
        let stateComponent = StateComponent()
        self.addComponent(stateComponent)

        self.addComponent(ControlableComponent(delegate: self))
        self.addComponent(MovementComponent(moveSpeed: 2))
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
        self.component(ofType: StateComponent.self)?.updateState(moving: isMoving)
    }
    
    public func handleButtonAPressed() {
        
    }
}

