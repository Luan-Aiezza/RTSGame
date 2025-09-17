//
//  SceneConfiguration.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 17/09/25.
//

class SceneConfiguration {
    
    let inhibitors: [String]
    let spawners: [String]
    var waveConfig: [WaveConfiguration] = []
    
    init(inhibitorsQuantity: Int, spawnersQuantity: Int) {
        self.inhibitors = SceneConfiguration.buildArrayWithNames(with: "Inhibitor_", howMany: inhibitorsQuantity)
        self.spawners = SceneConfiguration.buildArrayWithNames(with: "Spawn_", howMany: spawnersQuantity)
        print(inhibitors)
        print(spawners)
    }
    
    private static func buildArrayWithNames(with entityName: String, howMany quantity: Int) -> [String]{
        var names: [String] = []
        for i in 0..<quantity{
            names.append(entityName+String(i+1))
        }
        return names
    }
}
