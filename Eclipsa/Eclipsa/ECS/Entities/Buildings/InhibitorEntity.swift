//
//  EnemyNexusEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class InhibitorEntity: BuildingEntity {
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .sun, maxHealth: 1000)
        self.addComponent(ResourceGeneratorComponent(rate: 7, maxResourcePerGeneration: 1))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
