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
                
                // 1.0) Phase overlay (tela de início de fase / carregamento) → topo absoluto
                if node.name == "PhaseOverlay" || node.parent?.name == "PhaseOverlay" {
                    let baseZ: CGFloat = 11_000.0
                    if let name = node.name {
                        switch name {
                        case "PhaseOverlay":
                            node.zPosition = baseZ
                            return
                        case "PhaseOverlayBG":
                            node.zPosition = baseZ + 0.0 // fundo preto
                            return
                        case "PhaseSnow":
                            node.zPosition = baseZ + 0.31 // neve à frente do fundo
                            return
                        case "PhaseTitle", "PhaseCrown", "PhaseIcon", "PhaseGirl":
                            node.zPosition = baseZ + 0.3 // conteúdo à frente da neve
                            return
                        default:
                            node.zPosition = baseZ + 0.25
                            return
                        }
                    } else {
                        node.zPosition = baseZ + 0.25
                        return
                    }
                }
                
                // 1.1) Defeat overlay e seus filhos → sempre à frente do jogo
                if node.name == "DefeatOverlay" || node.parent?.name == "DefeatOverlay" {
                    // Base para o overlay todo
                    let baseZ: CGFloat = 11_000.0
                    
                    // Ordenação interna do overlay:
                    // Menu_Background < DefeatOverlayBG < LoseEffect < Labels/Botões/Título
                    if let name = node.name {
                        switch name {
                        case "DefeatOverlay":
                            node.zPosition = baseZ
                            return
                        case "DefeatMenuBackground":
                            node.zPosition = baseZ + 0.0
                            return
                        case "DefeatOverlayBG":
                            node.zPosition = baseZ + 0.1
                            return
                        case "RestartButton", "DefeatTitle":
                            node.zPosition = baseZ + 0.3
                            return
                        default:
                            // Qualquer outro filho do overlay que não seja reconhecido:
                            // por segurança, coloque acima do efeito e abaixo dos botões/título
                            node.zPosition = baseZ + 0.25
                            return
                        }
                    } else {
                        // Nó sem nome mas filho do overlay: posiciona acima do efeito
                        node.zPosition = baseZ + 0.25
                        return
                    }
                }
                
                // 1.1b) Win overlay e seus filhos → sempre à frente do jogo (mesmas regras do Defeat)
                if node.name == "WinOverlay" || node.parent?.name == "WinOverlay" {
                    let baseZ: CGFloat = 11_000.0
                    if let name = node.name {
                        switch name {
                        case "WinOverlay":
                            node.zPosition = baseZ
                            return
                        case "WinMenuBackground":
                            node.zPosition = baseZ + 0.0
                            return
                        case "DefeatOverlayBG", "WinOverlayBG":
                            // aceitar tanto o nome antigo quanto o novo para o fundo escuro
                            node.zPosition = baseZ + 0.1
                            return
                        case "ContinueButton", "WinTitle":
                            node.zPosition = baseZ + 0.3
                            return
                        default:
                            node.zPosition = baseZ + 0.25
                            return
                        }
                    } else {
                        node.zPosition = baseZ + 0.25
                        return
                    }
                }
                
                // 1.2) DialogueHUD (por classe, por pai ou por nome) → atrás do DefeatOverlay/PhaseOverlay
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
                // Fallback para outros nós de HUD com z alto (evita reclassificar DialogueHUD/DefeatOverlay/PhaseOverlay que já retornaram)
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
                // Phase overlay (fallback absoluto)
                if name == "PhaseOverlay" || node.parent?.name == "PhaseOverlay" {
                    let baseZ: CGFloat = 11_000.0
                    switch name {
                    case "PhaseOverlay":
                        node.zPosition = baseZ
                    case "PhaseOverlayBG":
                        node.zPosition = baseZ + 0.0
                    case "PhaseSnow":
                        node.zPosition = baseZ + 0.1
                    case "PhaseTitle", "PhaseCrown", "PhaseIcon", "PhaseGirl":
                        node.zPosition = baseZ + 0.3
                    default:
                        node.zPosition = baseZ + 0.25
                    }
                    return
                }
                // Defeat overlay e seus filhos → topo absoluto (fallback)
                if name == "DefeatOverlay" || node.parent?.name == "DefeatOverlay" {
                    // Mesma regra interna do overlay, fallback
                    let baseZ: CGFloat = 11_000.0
                    switch name {
                    case "DefeatOverlay":
                        node.zPosition = baseZ
                    case "DefeatMenuBackground":
                        node.zPosition = baseZ + 0.0
                    case "DefeatOverlayBG":
                        node.zPosition = baseZ + 0.1
                    case "RestartButton", "DefeatTitle":
                        node.zPosition = baseZ + 0.3
                    default:
                        node.zPosition = baseZ + 0.25
                    }
                    return
                }
                // Win overlay e seus filhos → topo absoluto (fallback)
                if name == "WinOverlay" || node.parent?.name == "WinOverlay" {
                    let baseZ: CGFloat = 11_000.0
                    switch name {
                    case "WinOverlay":
                        node.zPosition = baseZ
                    case "WinMenuBackground":
                        node.zPosition = baseZ + 0.0
                    case "DefeatOverlayBG", "WinOverlayBG":
                        node.zPosition = baseZ + 0.1
                    case "ContinueButton", "WinTitle":
                        node.zPosition = baseZ + 0.3
                    default:
                        node.zPosition = baseZ + 0.25
                    }
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

