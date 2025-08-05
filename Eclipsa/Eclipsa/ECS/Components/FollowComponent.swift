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
        
        guard let followerComponent = self.spriteNode,
              let targetComponent = self.target?.component(ofType: GKSKNodeComponent.self) else {
            return
        }
        
        let distance = calcDistance(from: targetComponent.node.position, to: followerComponent.node.position)
        let duration = calcDuration(from: distance)
//        print(duration)
        
//        followerComponent.node.run(.move(to: targetComponent.node.position, duration: 0.25))
        followerComponent.node.run(.move(to: targetComponent.node.position, duration: duration))
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
