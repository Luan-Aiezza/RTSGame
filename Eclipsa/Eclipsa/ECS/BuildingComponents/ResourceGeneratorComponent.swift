//
//  ResourceGeneratorComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

import GameplayKit

class ResourceGeneratorComponent: GKComponent {
    var rate: TimeInterval
    var maxResourcePerGeneration: Int
    var lastTimeUpdate: TimeInterval = 0
    var maxStoredResource: Int
    var storedResource: Int = 0
    
    init(rate: TimeInterval, maxResourcePerGeneration: Int = 1, maxStoredResource: Int = 10) {
        self.rate = rate
        self.maxResourcePerGeneration = maxResourcePerGeneration
        self.maxStoredResource = maxStoredResource
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func update(deltaTime seconds: TimeInterval) {
        lastTimeUpdate += seconds
        
        if lastTimeUpdate >= rate && storedResource < maxStoredResource {
            generateResource()
            lastTimeUpdate = 0
            print(storedResource)
        }
    }
    
    func generateResource() {
        let amount = min(maxResourcePerGeneration, maxStoredResource - storedResource)
        storedResource += amount
    }
    
}
