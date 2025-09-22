//
//  Tutorial.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/09/25.
//


class Tutorial: SceneConfiguration {
    init(){
        super.init(inhibitorsQuantity: 1, spawnersQuantity: 1)
        waveConfig = [
            WaveConfiguration(
                waveNumber: 1,
                duration: 30.0,
                spawnInterval: 2.0,
                maxTroopsPerBuilding: 2,
                difficultyMultiplier: 1.0
            )
        ]
    }
}
