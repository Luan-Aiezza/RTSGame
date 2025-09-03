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
        setTarget(nexus) // começa focado no Nexus
        configureBehavior()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func configureBehavior() {
        guard let troop = troop,
              let agentComponent = troop.component(ofType: AgentComponent.self) else { return }

        // Se o estado atual mandou parar, não mexe no comportamento
        if let state = troop.stateMachineComponent.stateMachine.currentState,
           state is TroopIdleState || state is TroopAttackState {
            return
        }

        var newTarget: GKEntity? = nil

        // Procura inimigos próximos
        if let range = troop.component(ofType: RangeComponent.self) {
            let enemyTeam: Team = (troop.component(ofType: TeamComponent.self)?.team == .sun) ? .moon : .sun
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

        // Se não achou inimigos, segue para o Nexus
        if newTarget == nil {
            newTarget = nexusTarget
        }

        if newTarget !== target {
            setTarget(newTarget)
        }

        super.configureBehavior()
    }

    public override func update(deltaTime seconds: TimeInterval) {
        guard let stateMachine = troop?.stateMachineComponent?.stateMachine else { return }

        // Só reconfigura se não estiver atacando
        if !(stateMachine.currentState is TroopAttackState) {
            configureBehavior()
        }

        // Não decidimos mais manualmente o estado aqui.
        // Idle/Follow/Attack já são controlados dentro dos próprios TroopStates.
    }
}

