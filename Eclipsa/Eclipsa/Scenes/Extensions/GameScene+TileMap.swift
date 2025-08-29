//
//  GameScene+TileMap.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 25/08/25.
//

import SpriteKit

extension SKNode {
    /// Aplica o filteringMode = .nearest em todos os SKSpriteNodes e SKTileMapNodes dentro da hierarquia
    func applyNearestFilterRecursively() {
        // Se for um SKSpriteNode, aplica
        if let sprite = self as? SKSpriteNode {
            sprite.texture?.filteringMode = .nearest
        }
        
        // Se for um SKTileMapNode, aplica em cada definição
        if let tileMap = self as? SKTileMapNode {
            for row in 0..<tileMap.numberOfRows {
                for col in 0..<tileMap.numberOfColumns {
                    if let def = tileMap.tileDefinition(atColumn: col, row: row) {
                        for texture in def.textures {
                            texture.filteringMode = .nearest
                        }
                    }
                }
            }
        }
        
        // Se for um emitter (partículas), aplica no texture da partícula
        if let emitter = self as? SKEmitterNode {
            emitter.particleTexture?.filteringMode = .nearest
        }
        
        // Repete para todos os filhos
        for child in children {
            child.applyNearestFilterRecursively()
        }
    }
}
