//  TroopBehaviorComponent.swift
//  Eclipsa
//  Componente para atribuir comportamentos de seguir e evitar às tropas via GKAgent2D

import GameplayKit

public class TroopBehaviorComponent: GKComponent {
    unowned let troop: TroopEntity
    unowned let player: UnitEntity
    let allTroops: () -> [TroopEntity]
    
    public init(troop: TroopEntity, player: UnitEntity, allTroops: @escaping () -> [TroopEntity]) {
        self.troop = troop
        self.player = player
        self.allTroops = allTroops
        super.init()
        configureBehavior()
    }
    
    private func configureBehavior() {
        guard let agentComponent = troop.component(ofType: AgentComponent.self),
              let playerAgent = player.component(ofType: AgentComponent.self)?.agent else { return }
        
        let behavior = GKBehavior()
        // Seguir o jogador
        let seekGoal = GKGoal(toSeekAgent: playerAgent)
        behavior.setWeight(1.0, for: seekGoal)
        
        // Evitar outras tropas
        let otherAgents = allTroops().compactMap { $0 !== troop ? $0.component(ofType: AgentComponent.self)?.agent : nil }
        if !otherAgents.isEmpty {
            let avoidGoal = GKGoal(toAvoid: otherAgents, maxPredictionTime: 0.5)
            behavior.setWeight(2.0, for: avoidGoal)
        }
        agentComponent.agent.behavior = behavior
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        // Atualiza goals dinamicamente caso o grupo mude
        configureBehavior()
    }
    
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
