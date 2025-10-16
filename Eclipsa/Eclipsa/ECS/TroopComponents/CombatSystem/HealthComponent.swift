// HealthComponent.swift
// Componente de vida para entidades. Coloque este arquivo na raiz do projeto se necessário.

import SpriteKit
import GameplayKit

import SpriteKit
import GameplayKit
import BehindGameKit

public class HealthComponent: GKComponent {
    public var currentHealth: Int
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
        
        if isDead {
            handleDeath()
        }
    }
    
    public func heal(_ amount: Int) {
        guard currentHealth > 0 else { return }
        currentHealth = min(currentHealth + amount, maxHealth)
        onHealthChanged?(currentHealth, maxHealth)
    }
    
    func restoreFullHealth() {
        DispatchQueue.main.async{
            self.currentHealth = self.maxHealth
            self.onHealthChanged?(self.currentHealth, self.maxHealth)
        }
    }
    
    public func setHealth(_ value: Int) {
        currentHealth = min(max(value, 0), maxHealth)
        onHealthChanged?(currentHealth, maxHealth)
        
        if isDead {
            handleDeath()
        }
    }
    
    private func handleDeath() {
        guard let entity = entity else { return }

        // Marca como morta imediatamente (assim updates não rodam mais)
        entity.component(ofType: TroopBehaviorComponent.self)?.invalidate()

        if let anim = entity.component(ofType: AnimationComponent.self) {
            anim.runAnimation(for: .die)

            // Opção B:
            // Captura o node antes de remover do manager para garantir limpeza visual/física
            let capturedNode = entity.component(ofType: GKSKNodeComponent.self)?.node

            // remove do EntityManager logo aqui (para sair de allTroops)
            if !(entity is InhibitorEntity) {
                SKEntityManager.shared.remove(entity)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    // Limpa ações e filhos, remove da cena
                    capturedNode?.removeAllActions()
                    capturedNode?.removeAllChildren()
                    capturedNode?.removeFromParent()
                    capturedNode?.physicsBody = nil
                    // Como o SKPhysicsBodyComponent zera physicsBody no willRemoveFromEntity,
                    // e a entidade pode já ter sido desalocada, garantimos aqui que o physicsBody não permaneça.
                }
            }
            // espera só para remover o nó visual, sem depender da entidade existir

        } else {
            if !(entity is InhibitorEntity) {
                SKEntityManager.shared.remove(entity)
                entity.destroy()
            }
        }
    }

    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

