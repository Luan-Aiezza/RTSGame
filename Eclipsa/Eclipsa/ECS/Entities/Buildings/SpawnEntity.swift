//
//  EnemyNexusEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class SpawnEntity: BuildingEntity {
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .moon, maxHealth: 1000)
        // Adicionar componente para para gerar tropas inimigas
        let spawnerComponent = TroopSpawnerComponent()
        spawnerComponent.setupWithScene(WaveManager.shared.scene!)
        addComponent(spawnerComponent)
        
        WaveManager.shared.registerEnemyBuilding(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
