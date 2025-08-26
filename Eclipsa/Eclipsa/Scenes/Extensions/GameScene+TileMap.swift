//
//  GameScene+TileMap.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 25/08/25.
//

import SpriteKit

extension GameScene {
    func applyNearestFilterToTileMaps() {
        // Procura todos os SKTileMapNode na cena
        enumerateChildNodes(withName: "//.*") { node, _ in
            if let tileMap = node as? SKTileMapNode {
                for row in 0..<tileMap.numberOfRows {
                    for col in 0..<tileMap.numberOfColumns {
                        if let def = tileMap.tileDefinition(atColumn: col, row: row) {
                            def.textures.forEach { texture in
                                texture.filteringMode = .nearest
                            }
                        }
                    }
                }
            }
        }
    }
}
