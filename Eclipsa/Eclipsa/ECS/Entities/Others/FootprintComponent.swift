//
//  FootprintComponent.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 16/10/25.
//

import GameplayKit
import SpriteKit

final class FootprintComponent: GKComponent {
    weak var scene: SKScene?
    private var lastFootprintTime: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.1
    private var leftFootNext = true
    private var lastPosition: CGPoint?
    private var distanceAccum: CGFloat = 0
    private let stepSpacing: CGFloat = 6 // distância mínima entre pegadas
    
    init(scene: SKScene) {
        self.scene = scene
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard let troopNode = entity?.component(ofType: GKSKNodeComponent.self)?.node,
              let scene = scene else { return }

        let currentPos = troopNode.position

        // Se já temos uma última posição, acumula a distância percorrida
        if let last = lastPosition {
            let dx = currentPos.x - last.x
            let dy = currentPos.y - last.y
            let delta = sqrt(dx*dx + dy*dy)
            distanceAccum += delta
        }

        // Usa um pequeno gate temporal para evitar excesso por jitter
        let currentTime = CACurrentMediaTime()
        if distanceAccum >= stepSpacing && (currentTime - lastFootprintTime) > spawnInterval {
            spawnFootprint(at: currentPos, in: scene)
            lastFootprintTime = currentTime
            distanceAccum = 0
        }

        // Atualiza a última posição no fim do frame
        lastPosition = currentPos
    }
    
    private func spawnFootprint(at position: CGPoint, in scene: SKScene) {
        let offset: CGFloat = 1.0
        let dx: CGFloat = leftFootNext ? offset : -offset
        let dy: CGFloat = -18
        
        let footprint = SKSpriteNode(imageNamed: "step")
        footprint.size = CGSize(width: 4, height: 2)
        footprint.position = CGPoint(x: position.x + dx, y: position.y + dy)
        footprint.zPosition = -position.y - 0.1
        footprint.alpha = 0.8
        
        let action = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 2.0),
            SKAction.removeFromParent()
        ])
        footprint.run(action)
        
        scene.addChild(footprint)
        leftFootNext.toggle()
    }
}

