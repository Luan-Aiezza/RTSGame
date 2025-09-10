//
//  ResourceHandler.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

class ResourceHandler{
    static let shared = ResourceHandler()
    
    private let maxAmountOfResources: Int = 20
    private var storedResources: Int = 6
    
    private init() {}
    
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
