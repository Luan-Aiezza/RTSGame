//
//  Phase4.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 18/09/25.
//

class Phase4: SceneConfiguration {
    init() {
        super.init(inhibitorsQuantity: 3,
                   spawnersQuantity: 5,
                   spawnInterval: 20.0,   // fila anda a cada 12s
                   troopsPerGroup: 5)     // 3 tropas por vez
    }
}
