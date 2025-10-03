//
//  Tutorial.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/09/25.
//


class Tutorial: SceneConfiguration {
    init() {
        super.init(inhibitorsQuantity: 2,
                   spawnersQuantity: 1,
                   spawnInterval: 20.0,   // fila anda a cada 12s
                   troopsPerGroup: 2)     // 3 tropas por vez
    }
}
