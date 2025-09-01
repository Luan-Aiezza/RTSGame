//
//  DummyEntity.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 07/08/25.
//


import SpriteKit
import GameplayKit
import BehindGameKit


public class DummyEntity: GKEntity {

    public override init() {
        super.init()

        let spriteNode = SKSpriteNode(texture: nil, color: .green, size: CGSize(width: 64, height: 64))
        self.addComponent(GKSKNodeComponent(node: spriteNode))

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


extension DummyEntity: ControlableDelegate {
    public func handleMovement(direction: CGPoint) {
        moveComponent?.change(direction: direction)
    }
    
    public func handleButtonAPressed() {
        
    }
}
