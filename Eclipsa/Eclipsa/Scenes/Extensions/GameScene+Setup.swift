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
        setupRTSAiming()
        
        controlledEntity.addComponent(AimControlComponent(delegate: aimingSystem!))
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
    
    func addTroop(at point: CGPoint, team: Team) -> TroopEntity{
        let troop = TroopEntity.createTroop(at: point, team: team)
        SKEntityManager.shared.add(troop)
        if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
            addChild(node)
        }
        return troop
    }

    func setupTroops() {
        for _ in 0..<6{
            if let troop = controlledEntity.generator?.generateTroop(),
               let node = troop.component(ofType: AnimationComponent.self)?.node{
                addChild(node)
                troops.append(troop)
                SKEntityManager.shared.add(troop)
            }
        }
          // Inimigos
        let basePosition = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero
          let enemyPositions = [
              CGPoint(x: basePosition.x - 50, y: basePosition.y),
              CGPoint(x: basePosition.x - 90, y: basePosition.y - 90),
              CGPoint(x: basePosition.x - 120, y: basePosition.y + 90)
          ]
          troops += enemyPositions.map { addTroop(at: $0, team: .moon) }
        
        
      }


    func setupUI() {
        troopControlSystem = TroopControlSystem(scene: self, troops: troops, targetEntity: controlledEntity)
        troopControlButtons = TroopControlButtons(size: self.size, troopControlSystem: troopControlSystem)
        setupCommandButton()
        setupReleaseButton()
        camera?.addChild(troopControlButtons)
    }
    
   private func setupCommandButton(){
       cancelButton = CommandButton(position: Position.cancelButton(size: self.size), name: "Cancel")
        cancelButton.onTouch = { [weak self] in
            self?.aimingSystem?.cancelAiming()
            self?.cancelButton.toggleCommand(value: true)
        }
       cancelButton.toggleCommand(value: true)
        camera?.addChild(cancelButton)
    }
    
    private func setupReleaseButton() {
        releaseButton = CommandButton(position: Position.releaseButton(size: self.size), name: "Release", color: .blue)
        releaseButton.onTouch = { [weak self] in
            self?.aimingSystem?.startAiming()
        }
        releaseButton.toggleCommand(value: false)
        camera?.addChild(releaseButton)
    }
}
