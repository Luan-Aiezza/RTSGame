//
//  FollowComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 01/08/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

class FollowComponent: GKComponent {
    
    var target: GKEntity?
    var targetNode: SKNode?
    var speed: CGFloat
    
    private var spriteNode: GKSKNodeComponent? {
        self.entity?.component(ofType: GKSKNodeComponent.self) as? GKSKNodeComponent
    }
    
    init(speed: CGFloat) {
        self.speed = speed
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        guard let followerComponent = self.spriteNode else { return }
        
        // Determina a posição do alvo
        let targetPosition: CGPoint?
        if let entityTarget = target?.component(ofType: GKSKNodeComponent.self)?.node {
            targetPosition = entityTarget.position
        } else if let nodeTarget = targetNode {
            targetPosition = nodeTarget.position
        } else {
            return
        }
        
        // Calcula distância
        let distance = CGPoint(x: targetPosition!.x - followerComponent.node.position.x,
                               y: targetPosition!.y - followerComponent.node.position.y)
        let duration = min(sqrt(distance.x * distance.x + distance.y * distance.y) / speed, 0.3)
        
        followerComponent.node.run(.move(to: targetPosition!, duration: duration))
    }
    
    private func calcDistance(from follower: CGPoint, to target: CGPoint) -> CGPoint {
        let distance = target - follower
        return distance
    }
    
    private func calcDuration(from distance: CGPoint) -> TimeInterval {
        let scalar = sqrt((pow(distance.x, 2) + pow(distance.y, 2)))
        let duration: TimeInterval = scalar / speed
        return duration
    }
}
