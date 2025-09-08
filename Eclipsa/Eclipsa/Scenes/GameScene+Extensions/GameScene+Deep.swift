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
            // 1) Ignora nós na hierarquia da câmera (HUD/UI/Overlays)
            if let cam = self.camera, node.inParentHierarchy(cam) {
                // Ainda assim, se for healthbar ou HUD, garanta topo absoluto
                if let name = node.name, name.hasPrefix("healthbar") || name.hasPrefix("hud") || name == "DefeatOverlay" {
                    node.zPosition = 10_000
                }
                return
            }
            
            // 2) Bypass explícito por nome (caso algo não esteja sob a câmera por algum motivo)
            if let name = node.name {
                // Health bars → sempre na frente
                if name.hasPrefix("healthbar") {
                    node.zPosition = 10_000
                    return
                }
                // HUD/UI → sempre na frente
                if name.hasPrefix("hud") {
                    node.zPosition = 10_000
                    return
                }
                // Defeat overlay e seus filhos → sempre na frente
                if name == "DefeatOverlay" || node.parent?.name == "DefeatOverlay" {
                    node.zPosition = 10_000
                    return
                }
            }
            
            // 3) Tilemaps de chão → sempre no fundo
            if let tileMap = node as? SKTileMapNode,
               let name = tileMap.name,
               groundTileMapNames.contains(name) {
                tileMap.zPosition = -10_000
                return
            }
            
            // 4) Tilemaps de árvores (Tree_*) → converter para sprites individuais
            if let tileMap = node as? SKTileMapNode,
               let name = tileMap.name,
               name.hasPrefix("Tree") {
                self.convertTileMapToSprites(tileMap: tileMap, baseName: name)
                return
            }
            
            // 5) Lógica padrão de profundidade
            node.zPosition = -node.position.y
        }
    }
}
