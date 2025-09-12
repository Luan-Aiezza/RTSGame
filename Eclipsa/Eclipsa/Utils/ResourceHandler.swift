//
//  ResourceHandler.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

import Combine

class ResourceHandler: ObservableObject {
    static let shared = ResourceHandler()
    
    private let maxAmountOfResources: Int = 6
    @Published private(set) var storedResources: Int
    
    private init() {
        storedResources = 0
    }
    
    func getStoredResources() -> Int {
        return storedResources
    }
    
    func getMaxAmountOfResources() -> Int {
        return maxAmountOfResources
    }
    
    func addResources(_ amount: Int) {
        guard amount > 0 else { return }
        // Impede ultrapassar o máximo
        let newValue = min(storedResources + amount, maxAmountOfResources)
        storedResources = newValue
    }
    
    func spendResources(_ amount: Int) {
        guard amount > 0 else { return }
        // Impede ir abaixo de zero
        let newValue = max(storedResources - amount, 0)
        storedResources = newValue
    }
}

