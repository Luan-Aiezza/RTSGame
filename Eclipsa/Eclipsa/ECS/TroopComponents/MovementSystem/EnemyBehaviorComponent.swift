
//
//  EnemyBehaviorComponent.swift
//  Eclipsa
//
//  Criado por Luan Aiezza em 03/09/25
//

import GameplayKit
import BehindGameKit

public class EnemyTroopBehaviorComponent: TroopBehaviorComponent {
    private weak var nexusTarget: GKEntity?
    private var nexusPosition: CGPoint?

    public init(troop: TroopEntity, nexus: GKEntity, allTroops: @escaping () -> Set<TroopEntity>) {
        self.nexusTarget = nexus
        if let nexusNode = nexus.component(ofType: GKSKNodeComponent.self)?.node {
            self.nexusPosition = nexusNode.position
        }
        super.init(troop: troop, target: nil, allTroops: allTroops)
        setTarget(nexus)
        self.configureBehavior() // força configuração inicial
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func configureBehavior() {
        guard let agentComponent = troop.component(ofType: AgentComponent.self) else { return }
        if let state = troop.stateMachineComponent.stateMachine.currentState {
            if state is TroopIdleState || state is TroopAttackState {
                return
            }
        }
        var newTarget: GKEntity? = nil
        if let range = troop.component(ofType: RangeComponent.self) {
            let enemyTeam = troop.component(ofType: TeamComponent.self)?.team == .sun ? Team.moon : Team.sun
            let nearbyEnemies = allTroops().filter {
                $0 !== troop &&
                $0.component(ofType: TeamComponent.self)?.team == enemyTeam &&
                ($0.component(ofType: HealthComponent.self)?.isDead == false) &&
                (range.contains(point: $0.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero))
            }
            if let firstEnemy = nearbyEnemies.first {
                newTarget = firstEnemy
            }
        }
        // Se não achou inimigos, vai para o Nexus
        if newTarget == nil {
            newTarget = nexusTarget
        }
        if newTarget !== target {
            setTarget(newTarget)
        }
        super.configureBehavior()
    }

    public override func update(deltaTime seconds: TimeInterval) {
        configureBehavior()
        
        // --- Atualiza a state machine de acordo com o target ---
        guard let stateMachineComponent = troop.stateMachineComponent else { return }
        let stateMachine = stateMachineComponent.stateMachine
        
        if let currentTarget = target as? BaseUnitEntity,
           let troopPos = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
           let targetPos = currentTarget.component(ofType: GKSKNodeComponent.self)?.node.position,
           let range = troop.component(ofType: RangeComponent.self)?.radius,
           let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
           let targetTeam = currentTarget.component(ofType: TeamComponent.self)?.team
        {
            let dist2 = pow(troopPos.x - targetPos.x, 2) + pow(troopPos.y - targetPos.y, 2)
            
            if troopTeam != targetTeam {
                if dist2 <= range * range {
                    if !(stateMachine.currentState is TroopAttackState) {
                        stateMachine.enter(TroopAttackState.self)
                    }
                } else {
                    if !(stateMachine.currentState is TroopFollowState) {
                        stateMachine.enter(TroopFollowState.self)
                    }
                }
            }
        } else {
            if !(stateMachine.currentState is TroopIdleState) {
                stateMachine.enter(TroopIdleState.self)
            }
        }
    }

}
