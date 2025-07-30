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
        
        let square = SKShapeNode(rectOf: CGSize(width: 32, height: 32))
        square.fillColor = .blue
        square.position = CGPoint(x: 0, y: 0)
        
        self.addComponent(GKSKNodeComponent(node: square))

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
    }
    
    public func handleButtonAPressed() {
        
    }
}
