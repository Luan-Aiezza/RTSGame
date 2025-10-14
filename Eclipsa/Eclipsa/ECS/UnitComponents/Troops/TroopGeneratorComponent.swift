//
//  TroopGeneratorComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/08/25.
//
import GameplayKit
import BehindGameKit

class TroopGeneratorComponent: GKComponent {
    weak var scene: GameScene?
    var spawnPosition: CGPoint {
        let entity = self.entity as? BaseUnitEntity
        return entity?.spriteNode.position ?? .zero
    }
    
    var spawnOffset: CGPoint {
        let angle = Double.random(in: 0..<2*Double.pi)
        let radius = Double.random(in: 30...50)
        return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
    }
    
    private var timer: DispatchSourceTimer?
    private var coolDown: TimeInterval = 1
    
    var generatedTroops: Set<TroopEntity> = []
    var limitTroops: Int = 5
    
    func generateTroop(troops: [TroopEntity]) -> TroopEntity?{
        if limitTroops > generatedTroops.count {
            let position = spawnPosition + spawnOffset
            let troop = TroopEntity.createTroop(at: position, team: Team.sun, troops: troops)
            // Anexa o comportamento de follow ao jogador para tropas aliadas
            attachAutoFollowIfAllied(to: troop)
            generatedTroops.insert(troop)
            return troop
        }
        stopGenerating()
        return nil
    }
    
    func startGenerating(troops: Set<TroopEntity> ,completion: @escaping ((TroopEntity?) -> Void)) {
        let queue = DispatchQueue(label: "troopGenerator")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: coolDown)
        timer?.setEventHandler{
            let troop = self.generateTroop(troops: Array(troops))
            DispatchQueue.main.async {
                completion(troop)
            }
        }
        timer?.resume()
    }
    
    func stopGenerating() {
        timer?.cancel()
        timer = nil
    }
    
    func generateRanged(troops: Set<TroopEntity>, completion: @escaping ((TroopEntity?) -> Void)){
        let position = spawnPosition + spawnOffset
        let troop = TroopFactory.makeRanged(team: .sun) {
            return Array(troops)
        }
        troop.spriteNode.position = position
        // Anexa o comportamento de follow ao jogador para tropas aliadas
        attachAutoFollowIfAllied(to: troop)
        generatedTroops.insert(troop)
        completion(troop)
        
    }
    
    func generateMelee(troops: Set<TroopEntity>, completion: @escaping ((TroopEntity?) -> Void)){
        let position = spawnPosition + spawnOffset
        let troop = TroopFactory.makeMelee(team: .sun) {
            return Array(troops)
        }
        troop.spriteNode.position = position
        // Anexa o comportamento de follow ao jogador para tropas aliadas
        attachAutoFollowIfAllied(to: troop)
        generatedTroops.insert(troop)
        completion(troop)
        
    }
    
    func findFreeSpawnPosition(
        near basePosition: CGPoint,
        maxAttempts: Int = 10,
        minDistance: CGFloat = 10
    ) -> CGPoint {
        for _ in 0..<maxAttempts {
           let candidate = spawnPosition + spawnOffset
            
            let isOccupied = SKEntityManager.shared.getAllEntities().contains{ entity in
                    if let entity = entity as? BuildingEntity,
                       let node = entity.component(ofType: GKSKNodeComponent.self)?.node{
                        return node.position.distance(to: candidate) < minDistance
                    }
                return true
            }
            
            if !isOccupied {
                return candidate
            }
        }
        
        // Não achou nenhuma posição livre depois de N tentativas
        return spawnPosition
    }
}

// MARK: - Private helpers
private extension TroopGeneratorComponent {
    func attachAutoFollowIfAllied(to troop: TroopEntity) {
        // Garante que só aplicamos a tropas aliadas (.sun)
        guard troop.component(ofType: TeamComponent.self)?.team == .sun else { return }
        
        // Recupera o jogador do time .sun
        guard let player = SKEntityManager.shared.getFirstEntity(ofType: UnitEntity.self),
              player.component(ofType: TeamComponent.self)?.team == .sun
        else { return }
        
        // Evita duplicar o componente se já existir
        if troop.component(ofType: TroopBehaviorComponent.self) == nil {
            let behavior = TroopBehaviorComponent(
                troop: troop,
                target: player,
                allTroops: {
                    // Snapshot das tropas atuais para o comportamento (igual ao usado no TroopControlSystem)
                    return SKEntityManager.shared.getAllGameTroops()
                }
            )
            // Força prioridade ao follow do jogador inicialmente
            behavior.manualTargetPoint = nil
            behavior.setTarget(player)
            troop.addComponent(behavior)
        } else {
            // Se já existir, apenas reconfigura para seguir o jogador
            let behavior = troop.component(ofType: TroopBehaviorComponent.self)
            behavior?.manualTargetPoint = nil
            behavior?.setTarget(player)
        }
    }
}
