//
//  SceneEntity.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 01/09/25.
//

import GameplayKit

class SceneEntity: GKEntity {
    init(scene: GameScene) {
        super.init()
        let spawner = SpawnerWaveComponent(
            scene: scene,
            intervaloEntreWaves: 15,
            pisoTropas: 2,
            limiteTropas: 12,
            crescimentoPorWave: 2,
            tipoDeTropa: .mage,
            maximoWaves: 4 // 🔹 Exemplo: essa fase terá 3 waves
        )
        addComponent(spawner)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
