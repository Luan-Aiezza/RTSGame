//
//  ResourceHandler.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

import Combine

class ResourceHandler: ObservableObject {
    static let shared = ResourceHandler()
    
    private let maxAmountOfResources: Int = 5
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
        storedResources += amount
    }
    
    func spendResources(_ amount: Int) {
        storedResources -= amount
    }
}
