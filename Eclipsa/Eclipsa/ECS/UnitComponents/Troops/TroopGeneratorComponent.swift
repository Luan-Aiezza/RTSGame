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
        let radius = Double.random(in: 80...100)
        return CGPoint(x: (cos(angle) * radius).magnitude, y: sin(angle) * radius)
    }
    
    private var timer: DispatchSourceTimer?
    private var coolDown: TimeInterval = 1
    
    var generatedTroops: Set<TroopEntity> = []
    var limitTroops: Int = 5
    
    func generateTroop(troops: [TroopEntity]) -> TroopEntity?{
        if limitTroops > generatedTroops.count {
            let position = spawnPosition + spawnOffset
            let troop = TroopEntity.createTroop(at: position, team: Team.sun, troops: troops)
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
