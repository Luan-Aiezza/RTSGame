//
//  BuildingEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class BuildingEntity: BaseUnitEntity {
    
    public init(node: SKSpriteNode, team: Team, maxHealth: Int) {
        let spriteSize = node.size
        let texture = node.texture ?? SKTexture(imageNamed: "placeholder")
        
        super.init(team: team,
                   maxHealth: maxHealth,
                   spriteSize: spriteSize,
                   idleTextures: [texture],
                   walkTextures: [texture])
        
        // substitui o node criado pelo BaseUnitEntity pelo que veio do .sks
        if let oldNode = self.component(ofType: GKSKNodeComponent.self)?.node {
            oldNode.removeFromParent()
            self.removeComponent(ofType: GKSKNodeComponent.self)
        }
        self.addComponent(GKSKNodeComponent(node: node))
        
        // remove comportamentos que não fazem sentido em prédios
        self.removeComponent(ofType: RangeComponent.self)
        self.removeComponent(ofType: AgentComponent.self)
        stateMachineComponent.stateMachine = GKStateMachine(states: [])
        
        // ✅ adiciona física de wall
        PhysicsSystem.setupBuildingPhysics(for: self, size: node.size)

        // ✅ adiciona barra de vida ajustando dinamicamente a posição
        let healthBar = HealthBarComponent(nodeHeight: node.size.height)
        self.addComponent(healthBar)

        if let healthComp = self.component(ofType: HealthComponent.self) {
            healthComp.onHealthChanged = { [weak self] hp, max in
                self?.component(ofType: HealthBarComponent.self)?.updateBar(health: hp, max: max)
            }
        }

        self.addComponent(healthBar)

        // liga a barra ao componente de vida
        if let healthComp = self.component(ofType: HealthComponent.self) {
            healthComp.onHealthChanged = { [weak self] hp, max in
                self?.component(ofType: HealthBarComponent.self)?.updateBar(health: hp, max: max)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
