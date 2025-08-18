//
//  States.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/08/25.
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

class AttackState: GKState {
    unowned let entity: GKEntity
    init(entity: GKEntity) { self.entity = entity }
    override func didEnter(from previousState: GKState?) {
        entity.component(ofType: AnimationComponent.self)?.runAnimation(for: .attack)
    }
}

class DieState: GKState {
    unowned let entity: GKEntity
    init(entity: GKEntity) { self.entity = entity }
    
    override func didEnter(from previousState: GKState?) {
        entity.component(ofType: AnimationComponent.self)?.runAnimation(for: .die)

        if let node = entity.component(ofType: GKSKNodeComponent.self)?.node {
            let duration = entity.component(ofType: AnimationComponent.self)?
                .node
                .action(forKey: "animation")?
                .duration ?? 0.5
            
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: duration),
                SKAction.removeFromParent()
            ])) { [weak self] in
                guard let entity = self?.entity else { return }
                for component in entity.components {
                    entity.removeComponent(ofType: type(of: component))
                }
            }
        }
    }
}


