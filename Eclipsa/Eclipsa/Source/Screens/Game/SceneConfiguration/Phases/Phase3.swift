//
//  Phase3.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 18/09/25.
//

class Phase3: SceneConfiguration {
    init() {
        super.init(inhibitorsQuantity: 3,
                   spawnersQuantity: 4,
                   spawnInterval: 20.0,   // fila anda a cada 12s
                   troopsPerGroup: 3)     // 3 tropas por vez
    }
}
