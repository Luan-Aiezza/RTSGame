//  TroopBehaviorComponent.swift
//  Eclipsa
//  Componente para atribuir comportamentos de seguir e evitar às tropas via GKAgent2D

import GameplayKit
import BehindGameKit

public class TroopBehaviorComponent: GKComponent {
    
    weak var troop: TroopEntity?
    public weak var target: GKEntity?
    let allTroops: () -> Set<TroopEntity>
    
    // Novo: ponto manual para onde o jogador mandou ir
    public var manualTargetPoint: CGPoint?
    private var manualTargetAgent: GKAgent2D?
    
    private var lastDefeatedTargetPosition: CGPoint?
    
    public init(troop: TroopEntity, target: GKEntity?, allTroops: @escaping () -> Set<TroopEntity>) {
        self.troop = troop
        self.target = target
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

        // Se não há alvo e não é um comando manual, tenta achar inimigo
        if target == nil && manualTargetPoint == nil {
            if let range = troop?.component(ofType: RangeComponent.self) {
                let enemyTeam = troop?.component(ofType: TeamComponent.self)?.team == .sun ? Team.moon : Team.sun
                let nearbyEnemies = allTroops().filter {
                    $0 !== troop &&
                    $0.component(ofType: TeamComponent.self)?.team == enemyTeam &&
                    ($0.component(ofType: HealthComponent.self)?.isDead == false) &&
                    (range.contains(point: $0.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero))
                }
                if let newTarget = nearbyEnemies.first {
                    setTarget(newTarget)
                    return
                } else if let lastPos = lastDefeatedTargetPosition {
                    manualTargetPoint = lastPos
                    configureBehavior()
                    return
                }
            }
        }
        

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
                self.target = nil
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
        
        // NOVO: evitar obstáculos fixos
        if let obstacles = (troop?.component(ofType: GKSKNodeComponent.self)?.node.scene?.userData?["TreeObstacles"] as? [GKPolygonObstacle]),
           !obstacles.isEmpty {
            let avoidObstacles = GKGoal(toAvoid: obstacles, maxPredictionTime: 1.0)
            behavior.setWeight(3.0, for: avoidObstacles)
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

