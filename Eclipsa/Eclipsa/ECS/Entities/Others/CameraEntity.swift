//
//  CameraEntity.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 01/08/25.
//

import GameplayKit
import BehindGameKit

class CameraEntity: GKEntity {
    
    
    func setupComponents(cameraNode: SKCameraNode) {
        self.addComponent(GKSKNodeComponent(node: cameraNode))
        self.addComponent(CameraComponent(cameraNode: cameraNode))
        self.addComponent(FollowComponent( speed: 75))
    }
    
    var cameraComponent: CameraComponent? {
        return self.component(ofType: CameraComponent.self)
    }
    
    var followComponent: FollowComponent? {
        return self.component(ofType: FollowComponent.self)
    }
    
    // Accept optional to allow clearing the follow target
    func followPlayer(player: GKEntity?) {
        followComponent?.target = player
    }
    
}
