//
//  GameScene+TileMap.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 25/08/25.
//

import SpriteKit
import GameplayKit

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

extension GameScene {
    func setupTreeCollisions(forTilemapNamed name: String = "Tree_1") {
        // Busca recursiva (funciona mesmo se o tilemap estiver dentro de um "World" ou similar)
        let candidates: [SKNode?] = [
            childNode(withName: name),
            childNode(withName: "//\(name)"),
            childNode(withName: name.lowercased()),
            childNode(withName: "//\(name.lowercased())")
        ]
        guard let tileMap = candidates.compactMap({ $0 as? SKTileMapNode }).first else {
            print("TileMap '\(name)' não encontrado na cena.")
            return
        }
        
        // Remove colliders anteriores se você reentrar na cena
        childNode(withName: "Tree_1_Colliders")?.removeFromParent()
        
        // Container só pra organizar na árvore de nodes
        let container = SKNode()
        container.name = "Tree_1_Colliders"
        addChild(container) // adiciona na cena (não como filho do tilemap)
        
        let tileSize = tileMap.tileSize
        var created = 0
        let trunkSize = CGSize(width: tileSize.width, // mais estreito
                               height: tileSize.height * 0.5) // metade inferior
        let trunkOffset = CGPoint(x: 0, y: -tileSize.height * 0.25) // desce o centro
        
        for row in 0..<tileMap.numberOfRows {
            for col in 0..<tileMap.numberOfColumns {
                // Basta checar se existe definição (tile não vazio)
                guard tileMap.tileDefinition(atColumn: col, row: row) != nil else { continue }
                
                // Posição correta do centro do tile
                let localPos = tileMap.centerOfTile(atColumn: col, row: row)
                let worldPos = tileMap.convert(localPos, to: self)
                
                let wallNode = SKNode()
                wallNode.name = "tree_collider"
                wallNode.position = worldPos
                
                let body = SKPhysicsBody(rectangleOf: trunkSize, center: trunkOffset)
                body.isDynamic = false
                body.affectedByGravity = false
                body.allowsRotation = false
                body.categoryBitMask = PhysicsCategory.wall
                body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.troop
                body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.troop
                
                wallNode.physicsBody = body
                container.addChild(wallNode)
                created += 1
            }
        }
        
        // Novo: coleção de obstáculos
        var obstacles: [GKPolygonObstacle] = []
        
        for row in 0..<tileMap.numberOfRows {
            for col in 0..<tileMap.numberOfColumns {
                guard tileMap.tileDefinition(atColumn: col, row: row) != nil else { continue }
                
                let localPos = tileMap.centerOfTile(atColumn: col, row: row)
                let worldPos = tileMap.convert(localPos, to: self)
                
                // Node físico para colisão SpriteKit
                let wallNode = SKNode()
                wallNode.name = "tree_collider"
                wallNode.position = worldPos
                
                let body = SKPhysicsBody(rectangleOf: trunkSize, center: trunkOffset)
                body.isDynamic = false
                body.categoryBitMask = PhysicsCategory.wall
                body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.troop
                body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.troop
                wallNode.physicsBody = body
                container.addChild(wallNode)
                
                // Obstacle para GameplayKit
                let halfW = trunkSize.width / 2
                let halfH = trunkSize.height / 2
                let points: [SIMD2<Float>] = [
                    SIMD2<Float>(Float(worldPos.x - halfW), Float(worldPos.y - halfH)),
                    SIMD2<Float>(Float(worldPos.x + halfW), Float(worldPos.y - halfH)),
                    SIMD2<Float>(Float(worldPos.x + halfW), Float(worldPos.y + halfH)),
                    SIMD2<Float>(Float(worldPos.x - halfW), Float(worldPos.y + halfH))
                ]
                let obstacle = GKPolygonObstacle(points: points)
                obstacles.append(obstacle)
                
                created += 1
            }
        }
        
        // Guarda os obstáculos na cena
        self.userData = self.userData ?? NSMutableDictionary()
        self.userData?["TreeObstacles"] = obstacles
    }
    
    func setupTreeCollisionsBorder(forTilemapNamed name: String = "Tree_2") {
        // Busca recursiva (funciona mesmo se o tilemap estiver dentro de um "World" ou similar)
        let candidates: [SKNode?] = [
            childNode(withName: name),
            childNode(withName: "//\(name)"),
            childNode(withName: name.lowercased()),
            childNode(withName: "//\(name.lowercased())")
        ]
        guard let tileMap = candidates.compactMap({ $0 as? SKTileMapNode }).first else {
            print("TileMap '\(name)' não encontrado na cena.")
            return
        }
        
        // Remove colliders anteriores se você reentrar na cena
        childNode(withName: "Tree_2_Colliders")?.removeFromParent()
        
        // Container só pra organizar na árvore de nodes
        let container = SKNode()
        container.name = "Tree_2_Colliders"
        addChild(container) // adiciona na cena (não como filho do tilemap)
        
        let tileSize = tileMap.tileSize
        var created = 0
        
        for row in 0..<tileMap.numberOfRows {
            for col in 0..<tileMap.numberOfColumns {
                // Basta checar se existe definição (tile não vazio)
                guard tileMap.tileDefinition(atColumn: col, row: row) != nil else { continue }
                
                // Posição correta do centro do tile
                let localPos = tileMap.centerOfTile(atColumn: col, row: row)
                let worldPos = tileMap.convert(localPos, to: self)
                
                let wallNode = SKNode()
                wallNode.name = "tree_collider"
                wallNode.position = worldPos
                
                let body = SKPhysicsBody(rectangleOf: tileSize)
                body.isDynamic = false
                body.affectedByGravity = false
                body.allowsRotation = false
                body.categoryBitMask = PhysicsCategory.wall
                body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.troop
                body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.troop
                
                wallNode.physicsBody = body
                container.addChild(wallNode)
                created += 1
            }
        }
    }
}

