import GameplayKit
import BehindGameKit
import SpriteKit

public class TroopBehaviorComponent: GKComponent {
    
    weak var troop: TroopEntity?
    
    /// Alvo atual escolhido automaticamente (inimigo em combate)
    private weak var currentTarget: GKEntity?
    
    /// Alvo fixo/fallback (Nexus para moon, destino/jogador para sun)
    public weak var defaultTarget: GKEntity?
    
    /// Todas as tropas no campo
    let allTroops: () -> Set<TroopEntity>
    
    /// Ponto manual definido pelo jogador
    public var manualTargetPoint: CGPoint?
    private var manualTargetAgent: GKAgent2D?
    
    // Defaults
    private let defaultAgentRadius: Float = 32.0
    private let meleeApproachRadius: Float = 48.0
    private let meleeApproachWindow: CGFloat = 92.0
    
    public init(
        troop: TroopEntity,
        target: GKEntity?,
        allTroops: @escaping () -> Set<TroopEntity>
    ) {
        self.troop = troop
        self.defaultTarget = target   // Nexus para moon, nil para sun
        self.allTroops = allTroops
        super.init()
        configureBehavior()
    }
    
    // MARK: - Target Resolution
    
    /// Resolve qual deve ser o alvo no momento
    private func resolveCurrentTarget(for troopLocal: TroopEntity) -> (entity: GKEntity?, point: CGPoint?) {
        
        // 1) Inimigos no range SEMPRE têm prioridade
        if let enemy = findEnemyInRange(for: troopLocal) {
            return (enemy, nil)
        }
        
        // 2) Se não tem inimigo, mas existe comando manual → vai pro ponto
        if let manualPoint = manualTargetPoint {
            return (nil, manualPoint)
        }
        
        // 3) Fallback: Nexus (moon) ou último objetivo do jogador (sun)
        if let fallback = defaultTarget {
            return (fallback, nil)
        }
        
        return (nil, nil)
    }
    
    /// Busca inimigos válidos dentro do range
    private func findEnemyInRange(for troopLocal: TroopEntity) -> BaseUnitEntity? {
        guard let range = troopLocal.component(ofType: RangeComponent.self) else { return nil }
        
        let myTeam = troopLocal.component(ofType: TeamComponent.self)?.team
        let enemyTeam: Team? = {
            guard let t = myTeam else { return nil }
            return t == .sun ? .moon : .sun
        }()
        
        var candidates: [BaseUnitEntity] = []
        
        if let enemyTeam = enemyTeam {
            let snapshot = allTroops()
            let enemyTroops = snapshot
                .compactMap { $0 as? BaseUnitEntity }
                .filter {
                    $0 !== troopLocal &&
                    $0.component(ofType: TeamComponent.self)?.team == enemyTeam &&
                    ($0.component(ofType: HealthComponent.self)?.isDead == false)
                }
            candidates.append(contentsOf: enemyTroops)
        }
        
        if myTeam == .moon {
            let allEntitiesSnapshot = SKEntityManager.shared.getAllEntities()
            
            let inhibitors = allEntitiesSnapshot
                .compactMap { $0 as? InhibitorEntity }
                .compactMap { $0 as BaseUnitEntity }
                .filter {
                    $0.component(ofType: TeamComponent.self)?.team == .sun &&
                    ($0.component(ofType: HealthComponent.self)?.isDead == false)
                }
            candidates.append(contentsOf: inhibitors)
            
            if let player = SKEntityManager.shared.getFirstEntity(ofType: UnitEntity.self),
               player.component(ofType: TeamComponent.self)?.team == .sun,
               player.component(ofType: HealthComponent.self)?.isDead == false {
                candidates.append(player)
            }
        }
        
        if myTeam == .sun {
            let allEntitiesSnapshot = SKEntityManager.shared.getAllEntities()
            let enemySpawns = allEntitiesSnapshot
                .compactMap { $0 as? SpawnEntity }
                .compactMap { $0 as BaseUnitEntity }
                .filter {
                    $0.component(ofType: TeamComponent.self)?.team == .moon &&
                    ($0.component(ofType: HealthComponent.self)?.isDead == false)
                }
            candidates.append(contentsOf: enemySpawns)
        }
        
        return candidates.first { candidate in
            if let pos = candidate.component(ofType: GKSKNodeComponent.self)?.node.position {
                return range.contains(point: pos)
            }
            return false
        }
    }
    
    // MARK: - Behavior Setup
    
    internal func configureBehavior() {
        guard let troopLocal = troop else { return }
        guard let agentComponent = troopLocal.component(ofType: AgentComponent.self) else { return }
        
        if let state = troopLocal.stateMachineComponent.stateMachine.currentState,
           state is TroopIdleState || state is TroopAttackState {
            return
        }
        
        // Resolve target
        let (resolvedEntity, resolvedPoint) = resolveCurrentTarget(for: troopLocal)
        currentTarget = resolvedEntity
        
        // Build behavior
        let behavior = GKBehavior()
        
        // Detect melee
        let isMelee = troopLocal.component(ofType: MeleeAttackComponent.self) != nil
        
        var distanceToTarget: CGFloat?
        var targetHasAgent = false
        
        if let enemy = resolvedEntity {
            if let targetAgent = enemy.component(ofType: AgentComponent.self)?.agent {
                targetHasAgent = true
                behavior.setWeight(1.0, for: GKGoal(toSeekAgent: targetAgent))
            } else if let node = enemy.component(ofType: GKSKNodeComponent.self)?.node {
                if manualTargetAgent == nil { manualTargetAgent = GKAgent2D() }
                manualTargetAgent?.position = SIMD2(Float(node.position.x), Float(node.position.y))
                if let manualAgent = manualTargetAgent {
                    behavior.setWeight(1.0, for: GKGoal(toSeekAgent: manualAgent))
                }
            }
            
            if let myPos = troopLocal.component(ofType: GKSKNodeComponent.self)?.node.position,
               let enemyPos = enemy.component(ofType: GKSKNodeComponent.self)?.node.position {
                distanceToTarget = myPos.distance(to: enemyPos)
            }
            
        } else if let point = resolvedPoint {
            if manualTargetAgent == nil { manualTargetAgent = GKAgent2D() }
            manualTargetAgent?.position = SIMD2(Float(point.x), Float(point.y))
            if let manualAgent = manualTargetAgent {
                behavior.setWeight(1.0, for: GKGoal(toSeekAgent: manualAgent))
            }
        }
        
        // Avoidance
        var shouldAddAvoidAgents = true
        var avoidAgentsWeight: Float = 2.0
        
        if isMelee, let d = distanceToTarget {
            if d <= meleeApproachWindow {
                agentComponent.agent.radius = meleeApproachRadius
                avoidAgentsWeight = 0.25
                if targetHasAgent { shouldAddAvoidAgents = false }
            } else {
                agentComponent.agent.radius = defaultAgentRadius
                avoidAgentsWeight = 2.0
            }
        } else {
            agentComponent.agent.radius = defaultAgentRadius
        }
        
        if shouldAddAvoidAgents {
            let snapshot = allTroops()
            let otherAgents = snapshot.compactMap { $0 !== troopLocal ? $0.component(ofType: AgentComponent.self)?.agent : nil }
            if !otherAgents.isEmpty {
                behavior.setWeight(avoidAgentsWeight, for: GKGoal(toAvoid: otherAgents, maxPredictionTime: 0.5))
            }
        }
        
        if let scene = troopLocal.component(ofType: GKSKNodeComponent.self)?.node.scene as? GameScene,
           let obstacles = scene.userData?["TreeObstacles"] as? [GKPolygonObstacle],
           !obstacles.isEmpty {
            behavior.setWeight(5.0, for: GKGoal(toAvoid: obstacles, maxPredictionTime: 1.0))
        }
        
        agentComponent.agent.behavior = behavior
    }
    
    // MARK: - Public
    
    public func invalidate() {
        if let agent = troop?.component(ofType: AgentComponent.self)?.agent {
            agent.behavior = nil
        }
        manualTargetAgent = nil
        manualTargetPoint = nil
        currentTarget = nil
        defaultTarget = nil
    }
    
    /// Define um novo alvo (inimigo / nexus / player). NÃO limpa `manualTargetPoint`.
    public func setTarget(_ newTarget: GKEntity?) {
        self.currentTarget = newTarget
        configureBehavior()
    }

    /// Define um ponto manual (ordem do jogador).
    public func setManualTargetPoint(_ point: CGPoint?) {
        self.manualTargetPoint = point
        // Reconfigure para aplicar imediatamente
        configureBehavior()
    }

    /// Limpa apenas o ponto manual sem mexer no currentTarget.
    public func clearManualTargetPoint() {
        self.manualTargetPoint = nil
        configureBehavior()
    }
    
    /// Getter público seguro para inimigo atual
    public func getCurrentEnemyTarget() -> BaseUnitEntity? {
        return currentTarget as? BaseUnitEntity
    }
    
    /// Getter público para qualquer alvo atual (pode ser inimigo, player, nexus etc)
    public func getCurrentTarget() -> GKEntity? {
        return currentTarget
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        guard troop != nil else { return }
        configureBehavior()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Helpers

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx*dx + dy*dy)
    }
}
