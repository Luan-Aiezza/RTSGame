//  TroopBehaviorComponent.swift
//  Eclipsa
//  Componente para atribuir comportamentos de seguir e evitar às tropas via GKAgent2D

import GameplayKit

public class TroopBehaviorComponent: GKComponent {
    unowned let troop: TroopEntity
    public var target: GKEntity?
    let allTroops: () -> [TroopEntity]
    
    // Novo: ponto manual para onde o jogador mandou ir
    public var manualTargetPoint: CGPoint?
    private var manualTargetAgent: GKAgent2D?
    
    public init(troop: TroopEntity, target: GKEntity?, allTroops: @escaping () -> [TroopEntity]) {
        self.troop = troop
        self.target = target
        self.allTroops = allTroops
        super.init()
        configureBehavior()
    }
    
    private func configureBehavior() {
        guard let agentComponent = troop.component(ofType: AgentComponent.self) else { return }

        let behavior = GKBehavior()

        if let enemy = target,
           let targetAgent = enemy.component(ofType: AgentComponent.self)?.agent {
            let seekGoal = GKGoal(toSeekAgent: targetAgent)
            behavior.setWeight(1.0, for: seekGoal)
        } else if let manualPoint = manualTargetPoint {
            if manualTargetAgent == nil {
                manualTargetAgent = GKAgent2D()
            }
            manualTargetAgent?.position = float2(Float(manualPoint.x), Float(manualPoint.y))
            if let manualAgent = manualTargetAgent {
                let seekGoal = GKGoal(toSeekAgent: manualAgent)
                behavior.setWeight(1.0, for: seekGoal)
            }
        }

        // Evitar colisão
        let otherAgents = allTroops().compactMap { $0 !== troop ? $0.component(ofType: AgentComponent.self)?.agent : nil }
        if !otherAgents.isEmpty {
            let avoidGoal = GKGoal(toAvoid: otherAgents, maxPredictionTime: 0.5)
            behavior.setWeight(2.0, for: avoidGoal)
        }

        agentComponent.agent.behavior = behavior
    }
    public func setTarget(_ newTarget: GKEntity?) {
        self.target = newTarget
        configureBehavior()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        configureBehavior()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
