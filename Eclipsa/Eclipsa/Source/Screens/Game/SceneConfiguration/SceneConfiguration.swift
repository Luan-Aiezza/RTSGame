//
//  SceneConfiguration.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 17/09/25.
//

import Foundation

class SceneConfiguration {
    
    let inhibitors: [String]
    let spawners: [String]
    
    // 👇 parâmetros novos para o WaveManager
    var spawnInterval: TimeInterval
    var troopsPerGroup: Int
    
    init(inhibitorsQuantity: Int,
         spawnersQuantity: Int,
         spawnInterval: TimeInterval = 10.0,
         troopsPerGroup: Int = 3) {
        
        self.inhibitors = SceneConfiguration.buildArrayWithNames(
            with: "Inhibitor_",
            howMany: inhibitorsQuantity
        )
        
        self.spawners = SceneConfiguration.buildArrayWithNames(
            with: "Spawn_",
            howMany: spawnersQuantity
        )
        
        // parâmetros de spawn que variam por fase
        self.spawnInterval = spawnInterval
        self.troopsPerGroup = troopsPerGroup
    }
    
    private static func buildArrayWithNames(with entityName: String, howMany quantity: Int) -> [String] {
        var names: [String] = []
        for i in 0..<quantity {
            names.append(entityName + String(i+1))
        }
        return names
    }
}
