// HealthComponent.swift
// Componente de vida para entidades. Coloque este arquivo na raiz do projeto se necessário.

import SpriteKit
import GameplayKit

public class HealthComponent: GKComponent {
    public private(set) var currentHealth: Int
    public let maxHealth: Int
    
    public var onHealthChanged: ((Int, Int) -> Void)?
    public var isDead: Bool { currentHealth <= 0 }
    
    public init(maxHealth: Int) {
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
        super.init()
    }
    
    public func takeDamage(_ amount: Int) {
        guard currentHealth > 0 else { return }
        currentHealth = max(currentHealth - amount, 0)
        onHealthChanged?(currentHealth, maxHealth)
    }
    
    public func heal(_ amount: Int) {
        guard currentHealth > 0 else { return }
        currentHealth = min(currentHealth + amount, maxHealth)
        onHealthChanged?(currentHealth, maxHealth)
    }
    
    public func setHealth(_ value: Int) {
        currentHealth = min(max(value, 0), maxHealth)
        onHealthChanged?(currentHealth, maxHealth)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
