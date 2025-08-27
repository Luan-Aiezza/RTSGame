//
//  UnitEntity.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 30/07/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class UnitEntity: BaseUnitEntity {
    
    public init(team: Team = .sun) {
        let spriteSize = CGSize(width: 32, height: 32)
        let idleTextures = (1...24).map { SKTexture(imageNamed: "Sun_Hero_Idle_\($0)") }
        let walkTextures = (1...5).map { SKTexture(imageNamed: "Sun_Hero_Walk_\($0)") }
        
        super.init(team: team,
                   maxHealth: 100,
                   spriteSize: spriteSize,
                   idleTextures: idleTextures,
                   walkTextures: walkTextures)
        
        self.addComponent(AimingComponent())
        self.addComponent(ControlableComponent(delegate: self))
        self.addComponent(AdaptedControlableComponent(delegate: self))
        self.addComponent(MovementComponent(moveSpeed: 1.5))
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

extension UnitEntity {
    var generator: TroopGeneratorComponent? {
        return self.component(ofType: TroopGeneratorComponent.self)
    }
}
