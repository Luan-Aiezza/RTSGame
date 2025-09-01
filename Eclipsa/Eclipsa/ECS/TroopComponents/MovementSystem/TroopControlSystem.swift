import Foundation
import SpriteKit
import GameplayKit

class TroopControlSystem {
    private weak var scene: GameScene?
    private(set) weak var targetEntity: UnitEntity?
    
    private var troops: Set<TroopEntity> {
        guard let troops = scene?.troops else {return []}
        return troops
    }
    
    init(scene: GameScene?, targetEntity: UnitEntity?) {
        self.scene = scene
        self.targetEntity = targetEntity
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

                let behavior = troop.component(ofType: TroopBehaviorComponent.self) ?? {
                    let b = TroopBehaviorComponent(
                        troop: troop,
                        target: targetEntity,
                        allTroops: { [weak self] in self?.troops ?? [] }
                    )
                    troop.addComponent(b)
                    return b
                }()

                // Prioridade máxima pro Follow:
                behavior.manualTargetPoint = nil
                behavior.setTarget(targetEntity)
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
