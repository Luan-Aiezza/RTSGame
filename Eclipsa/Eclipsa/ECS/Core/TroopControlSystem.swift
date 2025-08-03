import Foundation
import SpriteKit
import GameplayKit

class TroopControlSystem {
    private weak var scene: SKScene?
    private(set) var troops: [TroopEntity]
    private(set) weak var controlledEntity: UnitEntity?
    
    init(scene: SKScene?, troops: [TroopEntity], controlledEntity: UnitEntity?) {
        self.scene = scene
        self.troops = troops
        self.controlledEntity = controlledEntity
    }

    func updateTroops(_ troops: [TroopEntity]) {
        self.troops = troops
    }
    
    func commandTroopsToFollow() {
        guard let controlledEntity = controlledEntity,
              let rangeComponent = controlledEntity.component(ofType: RangeComponent.self),
              let playerTeam = controlledEntity.component(ofType: TeamComponent.self)?.team
        else { return }
        for troop in troops {
            if let troopPosition = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
               rangeComponent.contains(point: troopPosition),
               let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
               troopTeam == playerTeam {
                troop.startFollowing(controlledEntity)
            }
        }
    }

    func commandTroopsToStop() {
        guard let controlledEntity = controlledEntity,
              let rangeComponent = controlledEntity.component(ofType: RangeComponent.self),
              let playerTeam = controlledEntity.component(ofType: TeamComponent.self)?.team
        else { return }
        for troop in troops {
            if let troopPosition = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
               rangeComponent.contains(point: troopPosition),
               let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
               troopTeam == playerTeam {
                troop.stopFollowing()
            }
        }
    }
}

