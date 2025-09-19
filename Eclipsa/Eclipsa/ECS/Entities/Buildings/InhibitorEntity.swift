//
//  EnemyNexusEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class InhibitorEntity: BuildingEntity {
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .sun, maxHealth: 1500)
        self.addComponent(ResourceGeneratorComponent(rate: 5, maxResourcePerGeneration: 1)) //AJUSTAR
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
