//
//  BuildingEntity.swift
//  Eclipsa
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class BuildingEntity: BaseUnitEntity {
    
    public init(node: SKSpriteNode, team: Team, maxHealth: Int) {
        // usamos o node já existente na cena em vez de criar um novo
        let spriteSize = node.size
        let texture = node.texture ?? SKTexture(imageNamed: "placeholder")
        
        super.init(team: team,
                   maxHealth: maxHealth,
                   spriteSize: spriteSize,
                   idleTextures: [texture],
                   walkTextures: [texture]) // prédio não anda, mas precisa preencher
        
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

