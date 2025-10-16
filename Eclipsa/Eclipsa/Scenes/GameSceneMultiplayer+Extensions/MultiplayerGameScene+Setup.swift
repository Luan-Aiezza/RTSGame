//
//  MultiplayerGameScene+Setup.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 10/10/25.
//
import SpriteKit
import BehindGameKit
import GameplayKit

extension MultiplayerGameScene {
    func setupMultiplayerStructures() {
        // --- Sun Team ---
        if let node = childNode(withName: "Sun_Nexus") as? SKSpriteNode {
            let nexus = NexusEntity(node: node, team: .sun)
            nexus.addComponent(IndicatorAttackComponent())
            SKEntityManager.shared.add(nexus)
        }
        for i in 1...3 {
            if let node = childNode(withName: "Sun_Inhibitor_\(i)") as? SKSpriteNode {
                let inhibitor = InhibitorEntity(node: node, team: .sun, respawnDelay: 30, scene: self)
                SKEntityManager.shared.add(inhibitor)
            }
        }

        // --- Moon Team ---
        if let node = childNode(withName: "Moon_Nexus") as? SKSpriteNode {
            let nexus = NexusEntity(node: node, team: .moon)
            nexus.addComponent(IndicatorAttackComponent())
            SKEntityManager.shared.add(nexus)
        }
        for i in 1...3 {
            if let node = childNode(withName: "Moon_Inhibitor_\(i)") as? SKSpriteNode {
                let inhibitor = InhibitorEntity(node: node, team: .moon, respawnDelay: 30, scene: self)
                SKEntityManager.shared.add(inhibitor)
            }
        }
    }
    
    func setupPlayers() {
        // Prevent duplicate setup if already configured
        if controlledEntity != nil || remotePlayerEntity != nil {
            // Already set up; avoid duplicating nodes
            return
        }

        // Local player
        controlledEntity = UnitEntity(team: localTeam)
        SKEntityManager.shared.add(controlledEntity)

        // Ensure sprite node is not already attached elsewhere before adding
        if let parent = controlledEntity.spriteNode.parent, parent !== self {
            controlledEntity.spriteNode.removeFromParent()
        }
        if controlledEntity.spriteNode.parent == nil {
            addChild(controlledEntity.spriteNode)
        }

        physicsSystem.setupHeroPhysics(for: controlledEntity)
        cameraEntity?.followPlayer(player: controlledEntity)

        // Remote player (placeholder until position syncs)
        let remote = UnitEntity(team: remoteTeam)
        SKEntityManager.shared.add(remote)

        if let parent = remote.spriteNode.parent, parent !== self {
            remote.spriteNode.removeFromParent()
        }
        if remote.spriteNode.parent == nil {
            addChild(remote.spriteNode)
        }
        
        remotePlayerEntity = remote
    }
    
}
