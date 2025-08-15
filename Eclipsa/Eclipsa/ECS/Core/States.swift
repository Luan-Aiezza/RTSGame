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
