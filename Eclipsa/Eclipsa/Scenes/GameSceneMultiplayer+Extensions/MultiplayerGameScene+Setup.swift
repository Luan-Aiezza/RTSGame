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
        // Local player
        controlledEntity = UnitEntity(team: localTeam)
        SKEntityManager.shared.add(controlledEntity)
        addChild(controlledEntity.spriteNode)
        physicsSystem.setupHeroPhysics(for: controlledEntity)
        cameraEntity?.followPlayer(player: controlledEntity)
        
        // Remote player (placeholder até sincronizar posição)
        let remote = UnitEntity(team: remoteTeam)
        SKEntityManager.shared.add(remote)
        addChild(remote.spriteNode)
        remotePlayerEntity = remote
    }
}
