//
//  Phase1.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 17/09/25.
//

class Phase1: SceneConfiguration {
    init(){
        super.init(inhibitorsQuantity: 2, spawnersQuantity: 2)
        waveConfig = [
            WaveConfiguration(
                waveNumber: 1,
                duration: 30.0,
                spawnInterval: 2.0,
                maxTroopsPerBuilding: 2,
                difficultyMultiplier: 1.0
            ),
            WaveConfiguration(
                waveNumber: 2,
                duration: 45.0,
                spawnInterval: 1.8,
                maxTroopsPerBuilding: 3,
                difficultyMultiplier: 1.2
            ),
            WaveConfiguration(
                waveNumber: 3,
                duration: 60.0,
                spawnInterval: 1.5,
                maxTroopsPerBuilding: 4,
                difficultyMultiplier: 1.5
            ),
            WaveConfiguration(
                waveNumber: 4,
                duration: 75.0,
                spawnInterval: 1.2,
                maxTroopsPerBuilding: 5,
                difficultyMultiplier: 1.8
            ),
            WaveConfiguration(
                waveNumber: 5,
                duration: 90.0,
                spawnInterval: 1.0,
                maxTroopsPerBuilding: 6,
                difficultyMultiplier: 2.0
            )
        ]
    }
}
