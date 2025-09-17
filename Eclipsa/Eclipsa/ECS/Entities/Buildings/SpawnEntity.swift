//
//  EnemyNexusEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class SpawnEntity: BuildingEntity {
    
    public var onDestroyed: (() -> Void)?
    
    public init(node: SKSpriteNode) {
        super.init(node: node, team: .moon, maxHealth: 1000)
        
        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            health.onHealthChanged = { [weak self] current, max in
                // mantém o comportamento antigo (ex: atualizar barra de vida)
                previousCallback?(current, max)
                // dispara o callback de destruição quando a vida chegar a zero
                if current <= 0 {
                    self?.onDestroyed?()
                }
            }
        }
        
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
