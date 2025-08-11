// GameScene+DepthSort.swift
import SpriteKit
import GameplayKit

extension GameScene {
    func depthSortNodes() {
        if let playerNode = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node {
            playerNode.zPosition = 1000 - playerNode.position.y
        }
        for troop in troops {
            if let troopNode = troop.component(ofType: GKSKNodeComponent.self)?.node {
                troopNode.zPosition = 1000 - troopNode.position.y
            }
        }
    }
}
