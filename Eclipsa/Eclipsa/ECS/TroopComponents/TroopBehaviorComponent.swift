//  TroopBehaviorComponent.swift
//  Eclipsa
//  Componente para atribuir comportamentos de seguir e evitar às tropas via GKAgent2D

import GameplayKit

public class TroopBehaviorComponent: GKComponent {
    unowned let troop: TroopEntity
    public var target: GKEntity
    let allTroops: () -> [TroopEntity]
    
    /// Inicializa o componente com a tropa controlada, o alvo a seguir, e uma função que retorna todas as tropas para evitar colisões.
    /// Agora o alvo pode ser qualquer entidade, não apenas o jogador.
    public init(troop: TroopEntity, target: GKEntity, allTroops: @escaping () -> [TroopEntity]) {
        self.troop = troop
        self.target = target
        self.allTroops = allTroops
        super.init()
        configureBehavior()
    }
    
    private func configureBehavior() {
        guard let agentComponent = troop.component(ofType: AgentComponent.self),
              let targetAgent = target.component(ofType: AgentComponent.self)?.agent else { return }
        
        let behavior = GKBehavior()
        // Seguir o target (agora pode ser qualquer entidade)
        let seekGoal = GKGoal(toSeekAgent: targetAgent)
        behavior.setWeight(1.0, for: seekGoal)
        
        // Evitar outras tropas
        let otherAgents = allTroops().compactMap { $0 !== troop ? $0.component(ofType: AgentComponent.self)?.agent : nil }
        if !otherAgents.isEmpty {
            let avoidGoal = GKGoal(toAvoid: otherAgents, maxPredictionTime: 0.5)
            behavior.setWeight(2.0, for: avoidGoal)
        }
        agentComponent.agent.behavior = behavior
    }
    
    /// Atualiza o alvo a ser seguido em tempo de execução.
    public func setTarget(_ newTarget: GKEntity) {
        self.target = newTarget
        configureBehavior()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        // Atualiza goals dinamicamente caso o grupo ou o alvo mudem
        configureBehavior()
    }
    
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
