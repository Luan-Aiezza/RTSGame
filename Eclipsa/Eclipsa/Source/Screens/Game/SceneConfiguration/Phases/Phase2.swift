//
//  Phase2.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 18/09/25.
//

class Phase2: SceneConfiguration {
    init() {
        super.init(inhibitorsQuantity: 2,
                   spawnersQuantity: 3,
                   spawnInterval: 20.0,   // fila anda a cada 12s
                   troopsPerGroup: 2)     // 3 tropas por vez
    }
}
