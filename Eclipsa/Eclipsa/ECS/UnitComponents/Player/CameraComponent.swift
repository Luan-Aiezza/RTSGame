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
    
    init(cameraNode: SKCameraNode) {
        self.cameraNode = cameraNode
        self.cameraNode.setScale(1.0)
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didAddToEntity() {
        node = cameraNode
    }
    
    public func changeDirection(to direction: CGPoint){
        self.direction = .init(dx: direction.x, dy: direction.y)
    }
}
