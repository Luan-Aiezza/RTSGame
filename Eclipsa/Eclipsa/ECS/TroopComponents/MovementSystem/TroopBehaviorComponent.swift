import GameplayKit
import BehindGameKit
import SpriteKit

public class TroopBehaviorComponent: GKComponent {
    
    weak var troop: TroopEntity?
    public weak var target: GKEntity?           // alvo atual (inimigo em combate ou Nexus)
    public weak var defaultTarget: GKEntity?    // Nexus (ou outro ponto fixo)
    
    let allTroops: () -> Set<TroopEntity>
    
    // Novo: ponto manual para onde o jogador mandou ir
    public var manualTargetPoint: CGPoint?
    private var manualTargetAgent: GKAgent2D?
    
    private var lastDefeatedTargetPosition: CGPoint?
    
    public init(
        troop: TroopEntity,
        target: GKEntity?,
        allTroops: @escaping () -> Set<TroopEntity>
    ) {
        self.troop = troop
        self.target = target
        self.defaultTarget = target   // <- Nexus ou outro objetivo fixo
        self.allTroops = allTroops
        super.init()
        configureBehavior()
    }
    
    internal func configureBehavior() {
        // Capture strong ref to avoid use-after-free while we run this method
        guard let troopLocal = troop else { return }
        guard let agentComponent = troopLocal.component(ofType: AgentComponent.self) else { return }

        // If the troop's state demands stop, bail out early.
        if let state = troopLocal.stateMachineComponent.stateMachine.currentState {
            if state is TroopIdleState || state is TroopAttackState {
                return
            }
        }

        // --- 1) Reset target if dead and remember last position ---
        if let currentTarget = target as? BaseUnitEntity,
           currentTarget.component(ofType: HealthComponent.self)?.isDead == true {
            if let pos = currentTarget.component(ofType: GKSKNodeComponent.self)?.node.position {
                lastDefeatedTargetPosition = pos
            }
            target = nil
        }

        // --- 2) Determine fallback: nexus (defaultTarget) or last defeated point ---
        if target == nil && manualTargetPoint == nil {
            if let nexus = defaultTarget {
                target = nexus
            } else if let lastPos = lastDefeatedTargetPosition {
                manualTargetPoint = lastPos
            }
        }

        // --- 3) Try to find nearby enemies if relevant ---
        // Use strong refs and snapshots to avoid collection mutation/use-after-free issues.
        if let range = troopLocal.component(ofType: RangeComponent.self),
           (target === defaultTarget || target == nil) {

            let myTeam = troopLocal.component(ofType: TeamComponent.self)?.team
            let enemyTeam: Team? = {
                guard let t = myTeam else { return nil }
                return t == .sun ? .moon : .sun
            }()

            var candidateEntities: [BaseUnitEntity] = []

            if let enemyTeam = enemyTeam {
                // Make a snapshot of all troops (strong refs) so it can't change mid-iteration.
                let snapshot = allTroops()
                let enemyTroops = snapshot
                    .compactMap { $0 as? BaseUnitEntity }
                    .filter {
                        // Compare against the strong local ref
                        $0 !== troopLocal &&
                        $0.component(ofType: TeamComponent.self)?.team == enemyTeam &&
                        ($0.component(ofType: HealthComponent.self)?.isDead == false)
                    }
                candidateEntities.append(contentsOf: enemyTroops)
            }

            // If this troop is an enemy (.moon), also consider inhibitors and player unit.
            if myTeam == .moon {
                // We also snapshot the global entities to avoid mid-iteration mutation.
                let allEntitiesSnapshot = SKEntityManager.shared.getAllEntities()
                let inhibitors = allEntitiesSnapshot
                    .compactMap { $0 as? InhibitorEntity }
                    .compactMap { $0 as BaseUnitEntity }
                    .filter {
                        ($0.component(ofType: TeamComponent.self)?.team == .sun) &&
                        ($0.component(ofType: HealthComponent.self)?.isDead == false)
                    }
                candidateEntities.append(contentsOf: inhibitors)

                if let player = SKEntityManager.shared.getFirstEntity(ofType: UnitEntity.self) {
                    if player.component(ofType: TeamComponent.self)?.team == .sun,
                       player.component(ofType: HealthComponent.self)?.isDead == false {
                        candidateEntities.append(player)
                    }
                }
            }
            
            // Se esta tropa é do time .sun, considerar SpawnEntity do time .moon
            if myTeam == .sun {
                let allEntitiesSnapshot = SKEntityManager.shared.getAllEntities()
                let enemySpawns = allEntitiesSnapshot
                    .compactMap { $0 as? SpawnEntity }
                    .compactMap { $0 as BaseUnitEntity }
                    .filter {
                        ($0.component(ofType: TeamComponent.self)?.team == .moon) &&
                        ($0.component(ofType: HealthComponent.self)?.isDead == false)
                    }
                candidateEntities.append(contentsOf: enemySpawns)
            }

            // Filter candidates by range (use troopLocal's range helper)
            let inRangeCandidates: [BaseUnitEntity] = candidateEntities.filter {
                if let pos = $0.component(ofType: GKSKNodeComponent.self)?.node.position {
                    return range.contains(point: pos)
                }
                return false
            }

            // If we found a new target, use it. Otherwise, if we have lastDefeatedTargetPosition,
            // set manualTargetPoint to it (but do NOT recursively call configureBehavior()).
            if let newTarget = inRangeCandidates.first {
                setTarget(newTarget)
                return
            } else if let lastPos = lastDefeatedTargetPosition {
                // Set manual target point and continue — but avoid recursion.
                manualTargetPoint = lastPos
                // do not call configureBehavior() recursively; just continue to behavior creation
            }
        }

        // --- 4) Build GKBehavior for agent (seek target or manual point) ---
        let behavior = GKBehavior()

        if let enemy = self.target {
            if let targetAgent = enemy.component(ofType: AgentComponent.self)?.agent {
                let seekGoal = GKGoal(toSeekAgent: targetAgent)
                behavior.setWeight(1.0, for: seekGoal)
            } else if let nexusNode = enemy.component(ofType: GKSKNodeComponent.self)?.node {
                if manualTargetAgent == nil {
                    manualTargetAgent = GKAgent2D()
                }
                manualTargetAgent?.position = SIMD2<Float>(Float(nexusNode.position.x), Float(nexusNode.position.y))
                if let manualAgent = manualTargetAgent {
                    let seekGoal = GKGoal(toSeekAgent: manualAgent)
                    behavior.setWeight(1.0, for: seekGoal)
                }
            } else {
                // If the referenced enemy doesn't expose agent/node, fallback to defaultTarget.
                self.target = defaultTarget
            }
        } else if let manualPoint = manualTargetPoint {
            if manualTargetAgent == nil {
                manualTargetAgent = GKAgent2D()
            }
            manualTargetAgent?.position = SIMD2<Float>(Float(manualPoint.x), Float(manualPoint.y))
            if let manualAgent = manualTargetAgent {
                let seekGoal = GKGoal(toSeekAgent: manualAgent)
                behavior.setWeight(1.0, for: seekGoal)
            }
        }

        // --- 5) Avoid other agents: use snapshot and compare to troopLocal ---
        let snapshotForAgents = allTroops()
        let otherAgents = snapshotForAgents.compactMap { $0 !== troopLocal ? $0.component(ofType: AgentComponent.self)?.agent : nil }
        if !otherAgents.isEmpty {
            let avoidGoal = GKGoal(toAvoid: otherAgents, maxPredictionTime: 0.5)
            behavior.setWeight(2.0, for: avoidGoal)
        }
        
        // --- 6) Avoid static obstacles (trees) ---
        if let scene = troopLocal.component(ofType: GKSKNodeComponent.self)?.node.scene as? GameScene,
           let obstacles = scene.userData?["TreeObstacles"] as? [GKPolygonObstacle],
           !obstacles.isEmpty {

            let avoidObstaclesGoal = GKGoal(toAvoid: obstacles, maxPredictionTime: 1.0)
            behavior.setWeight(5.0, for: avoidObstaclesGoal) // peso mais alto para respeitar árvores
        }

        // Finally apply behavior
        agentComponent.agent.behavior = behavior
    }
    
    public func invalidate() {
        if let agent = troop?.component(ofType: AgentComponent.self)?.agent {
            agent.behavior = nil
        }
        manualTargetAgent = nil
        manualTargetPoint = nil
        target = nil
        defaultTarget = nil
    }
    
    public func setTarget(_ newTarget: GKEntity?) {
        self.target = newTarget
        configureBehavior()
    }
    
    // Update should early-return if troop was deallocated
    public override func update(deltaTime seconds: TimeInterval) {
        guard troop != nil else { return }
        configureBehavior()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
