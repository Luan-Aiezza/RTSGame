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
    
    func addTroop(at point: CGPoint, team: Team){
        
        let troop = TroopEntity.createTroop(at: point, team: team, troops: [])
        SKEntityManager.shared.add(troop)
        if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
            addChild(node)
        }
    }

    func setupTroops() {
        for _ in 0..<6{
            controlledEntity.generator?.startGenerating(troops: troops) { troop in
                if let troop = troop,
                   let node = troop.component(ofType: AnimationComponent.self)?.node{
                    self.addChild(node)
                    SKEntityManager.shared.add(troop)
                }
            }
        }


        
          // Inimigos
        let basePosition = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero
          let enemyPositions = [
              CGPoint(x: basePosition.x - 50, y: basePosition.y),
              CGPoint(x: basePosition.x - 60, y: basePosition.y - 10),
              CGPoint(x: basePosition.x - 120, y: basePosition.y + 90)
          ]
        enemyPositions.forEach { addTroop(at: $0, team: .moon) }
        
      }


    func setupUI() {
        self.troopControlSystem = TroopControlSystem(scene: self, targetEntity: controlledEntity)
        self.troopControlButtons = TroopControlButtons(size: self.size, troopControlSystem: troopControlSystem)
        camera?.addChild(troopControlButtons!)
        setupCommandButton()
        setupReleaseButton()
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
        releaseButton = CommandButton(position: Position.releaseButton(size: self.size), name: "R", color: .blue)
        releaseButton.onTouch = { [weak self] in
            self?.aimingSystem?.startAiming()
        }
        releaseButton.toggleCommand(value: false)
        camera?.addChild(releaseButton)
    }
}

