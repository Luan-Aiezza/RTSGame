//
//  GameScene+Particle.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 07/09/25.
//

import SpriteKit

extension GameScene {
    func setupSnow() {
        guard let camera = camera,
              let snow = SKEmitterNode(fileNamed: "SnowParticle.sks") else {
            return
        }
        
        snow.name = "SnowEffect"
        snow.zPosition = 9_999
        // posição: centro X, um pouco acima da tela no Y
        snow.position = CGPoint(x: 0, y: size.height / 2 + 50)
        snow.targetNode = self // partículas caem no mundo da cena
        
        camera.addChild(snow)
    }
}
