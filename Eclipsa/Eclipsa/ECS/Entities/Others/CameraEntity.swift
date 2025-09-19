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

extension SKCameraNode {
    func isNodeVisible(_ node: SKNode, in scene: SKScene) -> Bool {
        let nodePos = node.position
        let nodeInCameraSpace = scene.convert(nodePos, to: self)
        let halfWidth = scene.size.width / 2
        let halfHeight = scene.size.height / 2

        return abs(nodeInCameraSpace.x) <= halfWidth && abs(nodeInCameraSpace.y) <= halfHeight
    }
}
