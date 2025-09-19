//
//  ResourceGeneratorComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

import GameplayKit
import SpriteKit

extension Notification.Name {
    static let inhibitorDidGenerateResource = Notification.Name("inhibitorDidGenerateResource")
}

class ResourceGeneratorComponent: GKComponent {
    var rate: TimeInterval
    var maxResourcePerGeneration: Int
    var lastTimeUpdate: TimeInterval = 0
    
    init(rate: TimeInterval, maxResourcePerGeneration: Int = 1) {
        self.rate = rate
        self.maxResourcePerGeneration = maxResourcePerGeneration
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // Se já está no máximo, não acumula tempo (pausa/reset do cronômetro)
        if ResourceHandler.shared.getStoredResources() >= ResourceHandler.shared.getMaxAmountOfResources() {
            lastTimeUpdate = 0
            return
        }
        
        // Só acumula tempo quando há capacidade para gerar
        lastTimeUpdate += seconds
        
        if lastTimeUpdate >= rate {
            generateResource()
            lastTimeUpdate = 0
        }
    }
    
    func generateResource() {
        // Gera respeitando o máximo (ResourceHandler já faz clamp)
        ResourceHandler.shared.addResources(maxResourcePerGeneration)
        
        // Emite notificação para UI sobre geração neste Inhibitor/Building
        if let building = entity as? BuildingEntity,
           let node = building.component(ofType: GKSKNodeComponent.self)?.node {
            NotificationCenter.default.post(
                name: .inhibitorDidGenerateResource,
                object: building,
                userInfo: ["node": node]
            )
            // 🔊 Toca efeito sonoro de recurso, apenas se visível na câmera
            AudioManager.shared.playSoundIfVisible(named: "Resource_Effect", from: node)
        } else {
            // Caso não tenha node associado, toca mesmo assim (fallback)
            AudioManager.shared.playSound(named: "Resource_Effect")
        }
    }
}

