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
        guard let agentComponent = troop?.component(ofType: AgentComponent.self) else { return }

        if let state = troop?.stateMachineComponent.stateMachine.currentState {
            if state is TroopIdleState || state is TroopAttackState {
                // Se o state já mandou parar, não configuramos nada aqui
                return
            }
        }
        
        // Reseta o alvo inválido (ex: morreu)
        if let currentTarget = target as? BaseUnitEntity,
           currentTarget.component(ofType: HealthComponent.self)?.isDead == true {
            target = nil
        }
        
        // Se não há alvo de combate nem comando manual → volta pro Nexus
        if target == nil && manualTargetPoint == nil {
            if let nexus = defaultTarget {
                target = nexus
            }
        }
        
        // Se não há alvo e não é comando manual, tenta achar inimigo próximo
        if let range = troop?.component(ofType: RangeComponent.self),
           target === defaultTarget || target == nil {
            
            // Time inimigo
            let myTeam = troop?.component(ofType: TeamComponent.self)?.team
            let enemyTeam: Team? = {
                guard let t = myTeam else { return nil }
                return t == .sun ? .moon : .sun
            }()
            
            // 1) Tropas inimigas (comportamento atual)
            var candidateEntities: [BaseUnitEntity] = []
            if let enemyTeam = enemyTeam {
                let enemyTroops = allTroops().compactMap { $0 as BaseUnitEntity }.filter {
                    $0 !== troop &&
                    $0.component(ofType: TeamComponent.self)?.team == enemyTeam &&
                    ($0.component(ofType: HealthComponent.self)?.isDead == false)
                }
                candidateEntities.append(contentsOf: enemyTroops)
            }
            
            // 2) Se a tropa é inimiga (.moon), também considerar Inhibitors e o UnitEntity do jogador
            if myTeam == .moon {
                // Inhibitors aliados do jogador (time .sun)
                let inhibitors = SKEntityManager.shared.getAllEntities()
                    .compactMap { $0 as? InhibitorEntity }
                    .compactMap { $0 as BaseUnitEntity }
                    .filter {
                        ($0.component(ofType: TeamComponent.self)?.team == .sun) &&
                        ($0.component(ofType: HealthComponent.self)?.isDead == false)
                    }
                candidateEntities.append(contentsOf: inhibitors)
                
                // Jogador (UnitEntity) do time .sun
                if let player = SKEntityManager.shared.getFirstEntity(ofType: UnitEntity.self) {
                    if player.component(ofType: TeamComponent.self)?.team == .sun,
                       player.component(ofType: HealthComponent.self)?.isDead == false {
                        candidateEntities.append(player)
                    }
                }
            }
            
            // Filtrar por alcance
            let inRangeCandidates: [BaseUnitEntity] = candidateEntities.filter {
                if let pos = $0.component(ofType: GKSKNodeComponent.self)?.node.position {
                    return range.contains(point: pos)
                }
                return false
            }
            
            // Escolher o primeiro (ou o mais próximo, se quiser otimizar futuramente)
            if let newTarget = inRangeCandidates.first {
                setTarget(newTarget)
                return
            } else if let lastPos = lastDefeatedTargetPosition {
                manualTargetPoint = lastPos
                configureBehavior()
                return
            }
        }
        
        // --- Behavior padrão ---
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
                self.target = defaultTarget // volta pro Nexus se alvo inválido
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
        
        // Evitar colisão
        let otherAgents = allTroops().compactMap { $0 !== troop ? $0.component(ofType: AgentComponent.self)?.agent : nil }
        if !otherAgents.isEmpty {
            let avoidGoal = GKGoal(toAvoid: otherAgents, maxPredictionTime: 0.5)
            behavior.setWeight(2.0, for: avoidGoal)
        }
        
        // Evitar obstáculos fixos

        
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
