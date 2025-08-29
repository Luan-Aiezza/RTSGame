//
//  PlayerNexusEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class PlayerNexusEntity: BuildingEntity {
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .sun, maxHealth: 2000)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
