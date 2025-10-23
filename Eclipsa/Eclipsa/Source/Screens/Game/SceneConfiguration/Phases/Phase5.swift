//
//  Phase5.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 18/09/25.
//

class Phase5: SceneConfiguration {
    init() {
        super.init(inhibitorsQuantity: 3,
                   spawnersQuantity: 6,
                   spawnInterval: 20.0,   // fila anda a cada 12s
                   troopsPerGroup: 6)     // 3 tropas por vez
    }
}


