// GameScene+Setup.swift
import SpriteKit
import GameplayKit
import BehindGameKit

extension GameScene {
    func setupInputControllerIfNeeded() {
        if commandController == nil {
            commandController = AdaptedVirtualController(scene: self)
        }
    }

    func setupPlayer() {
        setupInputControllerIfNeeded()
        controlledEntity = UnitEntity(team: .sun)
        SKEntityManager.shared.add(controlledEntity)
//        controlledEntity.component(ofType: ControlableComponent.self)?
//            .setupController(inputHandler: commandInput, virtualController: commandController)
        controlledEntity.component(ofType: AimControlComponent.self)?.setupController(inputHandler: commandInput, virtualController: commandController)
        
        setupAdatpedVirtualController()
        physicsSystem.setupHeroPhysics(for: controlledEntity)
        if let rangeComp = controlledEntity.component(ofType: RangeComponent.self),
           let nodeComp = controlledEntity.component(ofType: GKSKNodeComponent.self) {
            let scene = nodeComp.node.scene ?? self
            let positionInScene = nodeComp.node.position
            rangeComp.node.position = positionInScene
            if rangeComp.node.parent !== scene {
                scene.addChild(rangeComp.node)
            }
        }
    }

    func setupCamera() {
        if let camera = self.camera {
            cameraEntity = CameraEntity()
            cameraEntity.setupComponents(cameraNode: camera)
            cameraEntity.followPlayer(player: controlledEntity)
            SKEntityManager.shared.add(cameraEntity)
        }
    }

    func setupTroops() {
        let basePosition = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero

        func createTroop(at position: CGPoint, team: Team) -> TroopEntity {
            let troop = TroopEntity(team: team)
            troop.component(ofType: GKSKNodeComponent.self)?.node.position = position
            physicsSystem.setupTroopPhysics(for: troop)

            // O RangeComponent já é adicionado pelo construtor de TroopEntity

            if let rangeComp = troop.component(ofType: RangeComponent.self),
               let nodeComp = troop.component(ofType: GKSKNodeComponent.self) {
                let scene = nodeComp.node.scene ?? self
                let positionInScene = nodeComp.node.position
                rangeComp.node.position = positionInScene
                if rangeComp.node.parent !== scene {
                    scene.addChild(rangeComp.node)
                }
            }

            SKEntityManager.shared.add(troop)
            if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
                addChild(node)
            }
            return troop
        }

        // Aliados
        let allyPositions = [
            CGPoint(x: basePosition.x + 50, y: basePosition.y),
            CGPoint(x: basePosition.x + 90, y: basePosition.y + 90),
            CGPoint(x: basePosition.x + 120, y: basePosition.y - 90)
        ]
        troops += allyPositions.map { createTroop(at: $0, team: .sun) }

        // Inimigos
        let enemyPositions = [
            CGPoint(x: basePosition.x - 50, y: basePosition.y),
            CGPoint(x: basePosition.x - 90, y: basePosition.y - 90),
            CGPoint(x: basePosition.x - 120, y: basePosition.y + 90)
        ]
        troops += enemyPositions.map { createTroop(at: $0, team: .moon) }
    }

    func setupUI() {
        troopControlSystem = TroopControlSystem(scene: self, troops: troops, targetEntity: controlledEntity)
        troopControlButtons = TroopControlButtons(size: self.size, troopControlSystem: troopControlSystem)
        camera?.addChild(troopControlButtons)
    }
}
