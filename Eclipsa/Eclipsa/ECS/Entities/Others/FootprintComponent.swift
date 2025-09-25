//
//  StepComponent.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 24/09/25.
//

import SpriteKit
import GameplayKit

class FootprintManager {
    weak var scene: SKScene?
    weak var player: SKNode?
    
    private var lastFootprintTime: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.1 // tempo entre pegadas
    private var leftFootNext = true // alterna pé esquerdo/direito
    
    init(scene: SKScene, player: SKNode) {
        self.scene = scene
        self.player = player
    }
    
    func update(deltaTime: TimeInterval, currentTime: TimeInterval) {
        guard let scene = scene, let player = player else { return }
        
        // só spawna se o player realmente estiver andando
        if let moveComp = (player.entity as? UnitEntity)?.moveComponent,
           moveComp.direction != .zero {
            
            if currentTime - lastFootprintTime > spawnInterval {
                spawnFootprint(at: player.position, in: scene)
                lastFootprintTime = currentTime
            }
        }
    }
    
    private func spawnFootprint(at position: CGPoint, in scene: SKScene) {
        let offset: CGFloat = 1.0
        let dx: CGFloat = leftFootNext ? offset : -offset
        let dy: CGFloat = -18 // levemente para baixo no Y
        
        let footprint = SKSpriteNode(imageNamed: "step")
        footprint.size = CGSize(width: 4, height: 2)
        footprint.position = CGPoint(x: position.x + dx, y: position.y + dy)
        footprint.zPosition = -position.y - 0.1 // fica no chão, levemente atrás do player
        footprint.alpha = 0.8
        
        // anima o fade out para desaparecer
        let action = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 2.0),
            SKAction.removeFromParent()
        ])
        footprint.run(action)
        
        scene.addChild(footprint)
        
        leftFootNext.toggle()
    }
}
