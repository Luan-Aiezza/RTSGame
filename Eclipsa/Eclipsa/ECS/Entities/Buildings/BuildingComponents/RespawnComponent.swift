//
//  RespawnComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 14/10/25.
//
import GameplayKit

class RespawnComponent: GKComponent {
    let respawnDelay: TimeInterval
    let originalNodeTemplate: SKSpriteNode
    weak var scene: SKScene?
    
    private var respawnTimer: TimeInterval = 0
    private var isWaitingToRespawn = false
    
    init(respawnDelay: TimeInterval, nodeTemplate: SKSpriteNode, scene: SKScene) {
        self.respawnDelay = respawnDelay
        self.originalNodeTemplate = nodeTemplate
        self.scene = scene
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func startRespawnCountdown() {
        isWaitingToRespawn = true
        respawnTimer = 0
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard isWaitingToRespawn else { return }
        print("chamando o update do RespawComponent")
        respawnTimer += seconds
        print(respawnTimer)
        if respawnTimer >= respawnDelay {
            triggerRespawn()
        }
    }
    
    private func triggerRespawn() {
        print("Triggei o Respawn")
        isWaitingToRespawn = false
        respawnTimer = 0
        
        if let entity = self.entity as? InhibitorEntity {
            entity.handleRespawn()
        }
    }
}
