// GameScene+AI.swift
import GameplayKit

extension GameScene {
    func nearestEnemyTroop(inRangeOf troop: TroopEntity) -> TroopEntity? {
        guard let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
              let position = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
              let range = troop.component(ofType: RangeComponent.self)?.radius else { return nil }
        
        return troops
            .filter { $0 !== troop }
            .filter { $0.component(ofType: TeamComponent.self)?.team != troopTeam }
            .filter { troopPos in
                guard let pos = troopPos.component(ofType: GKSKNodeComponent.self)?.node.position else { return false }
                let d2 = (position.x - pos.x) * (position.x - pos.x) + (position.y - pos.y) * (position.y - pos.y)
                return d2 <= range * range
            }
            .min { lhs, rhs in
                let pos1 = lhs.component(ofType: GKSKNodeComponent.self)!.node.position
                let pos2 = rhs.component(ofType: GKSKNodeComponent.self)!.node.position
                let d1 = (position.x - pos1.x) * (position.x - pos1.x) + (position.y - pos1.y) * (position.y - pos1.y)
                let d2 = (position.x - pos2.x) * (position.x - pos2.x) + (position.y - pos2.y) * (position.y - pos2.y)
                return d1 < d2
            }
    }
    
    func updateTroopTargets() {
        for troop in troops {
            guard let behavior = troop.component(ofType: TroopBehaviorComponent.self) else { continue }
            
            // Só tropas que já estavam em follow podem alternar
            let wasFollowingPlayer = (behavior.getCurrentEnemyTarget()) === controlledEntity || behavior.manualTargetPoint != nil
            
            if wasFollowingPlayer {
                if let enemy = nearestEnemyTroop(inRangeOf: troop) {
                    behavior.setTarget(enemy)
                } else if behavior.manualTargetPoint != nil {
                    behavior.setTarget(nil) // mantém ponto manual
                } else if let player = controlledEntity {
                    behavior.setTarget(player) // volta pro follow, se houver player
                }
            }
        }
    }
}
