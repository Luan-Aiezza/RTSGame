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
        
        // Nomes explícitos de botões/hud que conhecemos
        let explicitHUDButtonNames: Set<String> = ["Cancel", "R", "Melee", "Ranged", "Follow"]
        
        enumerateChildNodes(withName: "//*") { node, _ in
            // 1) Nós na hierarquia da câmera (HUD/UI/Overlays) têm regras específicas
            if let cam = self.camera, node.inParentHierarchy(cam) {
                
                // 1.1) Defeat overlay e seus filhos → topo absoluto
                if node.name == "DefeatOverlay" || node.parent?.name == "DefeatOverlay" {
                    node.zPosition = 11_000
                    return
                }
                
                // 1.2) DialogueHUD (por classe, por pai ou por nome) → atrás do DefeatOverlay
                if (node is DialogueHUD) || (node.parent is DialogueHUD) || node.name == "DialogueHUD" || node.parent?.name == "DialogueHUD" {
                    node.zPosition = 10_800
                    return
                }
                
                // 1.3) Botões e analógicos (HUD) → atrás do DialogueHUD
                if let name = node.name, explicitHUDButtonNames.contains(name) || name.hasPrefix("hud") {
                    node.zPosition = 10_600
                    return
                }
                // Analógico: identificar por classe AdaptedAnalogNode
                if node is AdaptedAnalogNode || node.parent is AdaptedAnalogNode {
                    node.zPosition = 10_600
                    return
                }
                // Fallback para outros nós de HUD com z alto (evita reclassificar DialogueHUD/DefeatOverlay que já retornaram)
                if node.zPosition >= 900 {
                    node.zPosition = 10_600
                    return
                }
                
                // 1.4) Healthbars também podem estar sob a câmera
                if let name = node.name, name.hasPrefix("healthbar") {
                    node.zPosition = 10_400
                    return
                }
                // Demais nós sob a câmera caem para regras gerais abaixo
            }
            
            // 2) Bypass explícito por nome (caso algo não esteja sob a câmera por algum motivo)
            if let name = node.name {
                // Health bars → à frente do resto, porém atrás dos botões/analógicos
                if name.hasPrefix("healthbar") {
                    node.zPosition = 10_400
                    return
                }
                // HUD/UI com prefixo → atrás do DialogueHUD
                if name.hasPrefix("hud") {
                    node.zPosition = 10_600
                    return
                }
                // Defeat overlay e seus filhos → topo absoluto (fallback)
                if name == "DefeatOverlay" || node.parent?.name == "DefeatOverlay" {
                    node.zPosition = 11_000
                    return
                }
                // Dialogue HUD por nome/pai (fallback)
                if name == "DialogueHUD" || node.parent?.name == "DialogueHUD" {
                    node.zPosition = 10_800
                    return
                }
                // Botões explícitos por nome (fallback)
                if explicitHUDButtonNames.contains(name) {
                    node.zPosition = 10_600
                    return
                }
                
                // 2.1) FollowEffect → sempre acima do chão e abaixo de tudo do mundo
                if name == "FollowEffect" {
                    // Chão está em -10_000; colocamos o efeito em -5_000 para ficar acima do chão e atrás do resto
                    node.zPosition = -5_000
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
