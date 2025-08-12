import Foundation
import SpriteKit
import GameplayKit

class TroopControlSystem {
    private weak var scene: SKScene?
    private(set) var troops: [TroopEntity]
    private(set) weak var targetEntity: UnitEntity?
    
    init(scene: SKScene?, troops: [TroopEntity], targetEntity: UnitEntity?) {
        self.scene = scene
        self.troops = troops
        self.targetEntity = targetEntity
    }

    func updateTroops(_ troops: [TroopEntity]) {
        self.troops = troops
    }
    
    func commandTroopsToFollow() {
        guard let targetEntity = targetEntity,
              let rangeComponent = targetEntity.component(ofType: RangeComponent.self),
              let playerTeam = targetEntity.component(ofType: TeamComponent.self)?.team
        else { return }
        for troop in troops {
            if let troopPosition = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
               rangeComponent.contains(point: troopPosition),
               let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
               troopTeam == playerTeam {
                // Ativa comportamento de seguir usando TroopBehaviorComponent
                if troop.component(ofType: TroopBehaviorComponent.self) == nil {
                    troop.addComponent(TroopBehaviorComponent(
                        troop: troop,
                        target: targetEntity,
                        allTroops: { [weak self] in self?.troops ?? [] }
                    ))
                }
            }
        }
    }

    func commandTroopsToStop() {
        guard let targetEntity = targetEntity,
              let rangeComponent = targetEntity.component(ofType: RangeComponent.self),
              let playerTeam = targetEntity.component(ofType: TeamComponent.self)?.team
        else { return }
        for troop in troops {
            if let troopPosition = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
               rangeComponent.contains(point: troopPosition),
               let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
               troopTeam == playerTeam {
                // Remove comportamento de seguir, fazendo a tropa parar no local
                troop.removeComponent(ofType: TroopBehaviorComponent.self)
            }
        }
    }
}
