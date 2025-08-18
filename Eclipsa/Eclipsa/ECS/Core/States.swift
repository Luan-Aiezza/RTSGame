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
        
        // Remover após a animação de morte
        if let anim = entity.component(ofType: AnimationComponent.self),
           let node = entity.component(ofType: GKSKNodeComponent.self)?.node {
            let duration = Double(anim.node.action(forKey: "animation")?.duration ?? 0.5)
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: duration),
                SKAction.removeFromParent()
            ]))
        }
    }
}

