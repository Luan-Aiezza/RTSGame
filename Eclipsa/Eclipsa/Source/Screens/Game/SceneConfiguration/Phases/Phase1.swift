//
//  Phase1.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 17/09/25.
//

class Phase1: SceneConfiguration {
    init() {
        super.init(inhibitorsQuantity: 2,
                   spawnersQuantity: 2,
                   spawnInterval: 20.0,   // fila anda a cada 12s
                   troopsPerGroup: 3)     // 3 tropas por vez
    }
}
