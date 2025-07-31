//
//  CameraComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 31/07/25.
//

import GameplayKit
import BehindGameKit

public class CameraComponent: GKSKNodeComponent {
    public var cameraNode: SKCameraNode
    public var direction: CGVector = .zero
    public var moveSpeed: CGFloat
    
    init(moveSpeed: CGFloat, cameraNode: SKCameraNode) {
        self.moveSpeed = moveSpeed
        self.cameraNode = cameraNode
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        let velocity = self.direction.normalized() * moveSpeed
        node.run(.move(by: velocity, duration: 1))
    }
    
    public override func didAddToEntity() {
        node = cameraNode
    }
    
    public func changeDirection(to direction: CGPoint){
        self.direction = .init(dx: direction.x, dy: direction.y)
    }
}
