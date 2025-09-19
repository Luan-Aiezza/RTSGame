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
        super.init(node: node, team: .moon, maxHealth: 1500)
        
        // ✅ Sobrescreve a animação de morte herdada
        if let anim = self.component(ofType: AnimationComponent.self) {
            let deathTextures: [SKTexture] = (1...12).map { SKTexture(imageNamed: "Soldier_Moon_Dead_\($0)") }
            anim.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.07, repeatForever: false)
        }
        
        // Configura callback de destruição
        if let health = self.component(ofType: HealthComponent.self) {
            let previousCallback = health.onHealthChanged
            health.onHealthChanged = { [weak self] current, max in
                previousCallback?(current, max)
                if current <= 0 {
                    AudioManager.shared.playSoundIfVisible(named: "Unvoke_Effect", from: node)
                    self?.onDestroyed?()
                }
            }
        }
        
        // ✅ Adiciona componente de spawn
        let spawnerComponent = TroopSpawnerComponent()
        spawnerComponent.setupWithScene(WaveManager.shared.scene!)
        addComponent(spawnerComponent)
        
        WaveManager.shared.registerEnemyBuilding(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
