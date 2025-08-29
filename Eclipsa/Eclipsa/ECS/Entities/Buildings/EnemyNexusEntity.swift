//
//  EnemyNexusEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class EnemyNexusEntity: BuildingEntity {
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .moon, maxHealth: 1000)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
