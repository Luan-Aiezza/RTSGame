// GameScene+DepthSort.swift
import SpriteKit
import GameplayKit

extension GameScene {
    
    /// Converte um SKTileMapNode em SKSpriteNodes individuais para aplicar profundidade por tile
    func convertTileMapToSprites(tileMap: SKTileMapNode, baseName: String) {
        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if let def = tileMap.tileDefinition(atColumn: col, row: row),
                   let texture = def.textures.first {
                    
                    let tilePosition = tileMap.centerOfTile(atColumn: col, row: row)
                    let scenePosition = tileMap.convert(tilePosition, to: self)
                    
                    let sprite = SKSpriteNode(texture: texture)
                    sprite.position = scenePosition
                    sprite.zPosition = -scenePosition.y
                    sprite.name = "\(baseName)_tile_\(col)_\(row)"
                    
                    addChild(sprite)
                }
            }
        }
        
        // remove o tilemap original da cena
        tileMap.removeFromParent()
    }
    
    
    /// Ordena profundidade de todos os nós
    func depthSortNodes() {
        let groundTileMapNames: Set<String> = [
            "Grass_1", "Grass_1_Variation",
            "Grass_2", "Grass_2_Variation",
            "Grass_3", "Grass_3_Variation"
        ]
        
        enumerateChildNodes(withName: "//*") { node, _ in
            // Ignora health bars → sempre na frente
            if let name = node.name, name.hasPrefix("healthbar") {
                node.zPosition = 10_000
                return
            }
            // ⛔ ignora nós da câmera (HUD/UI)
            if node.inParentHierarchy(self.camera!) {
                return
            }
            // HUD/UI → sempre na frente
            if let name = node.name, name.hasPrefix("hud") {
                node.zPosition = 10_000
                return
            }
            
            // Tilemaps de chão → sempre no fundo
            if let tileMap = node as? SKTileMapNode,
               let name = tileMap.name,
               groundTileMapNames.contains(name) {
                tileMap.zPosition = -10_000
                return
            }
            
            // Tilemaps de árvores (Tree_*) → converter para sprites individuais
            if let tileMap = node as? SKTileMapNode,
               let name = tileMap.name,
               name.hasPrefix("Tree") {
                self.convertTileMapToSprites(tileMap: tileMap, baseName: name)
                return
            }
            
            // Lógica padrão de profundidade
            node.zPosition = -node.position.y
        }
    }
}

