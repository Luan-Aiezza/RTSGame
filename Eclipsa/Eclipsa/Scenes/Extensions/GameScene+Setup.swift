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
    
    func setupPlayerNexus() {
        if let node = childNode(withName: "Nexus") as? SKSpriteNode {
            let nexus = PlayerNexusEntity(node: node)
            SKEntityManager.shared.add(nexus)

            self.userData = self.userData ?? NSMutableDictionary()
            self.userData?["playerNexus"] = nexus
        } else {
            print("⚠️ Node 'Nexus' não encontrado na cena!")
        }
    }

    func setupEnemyNexuses() {
        let enemyNames = ["EnemyNexus_1", "EnemyNexus_2", "EnemyNexus_3"]

        for name in enemyNames {
            if let node = childNode(withName: name) as? SKSpriteNode {
                let enemyNexus = EnemyNexusEntity(node: node)
                SKEntityManager.shared.add(enemyNexus)
            } else {
                print("⚠️ Node '\(name)' não encontrado na cena!")
            }
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
    
    func addTroop(at point: CGPoint, team: Team) -> TroopEntity{
        
        let troop = TroopEntity.createTroop(at: point, team: team, troops: [])
        SKEntityManager.shared.add(troop)
        if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
            addChild(node)
        }
        return troop
    }

    func setupTroops() {
        for _ in 0..<6{
            if let troop = controlledEntity.generator?.generateTroop(troops: troops),
               let node = troop.component(ofType: AnimationComponent.self)?.node{
                addChild(node)
                SKEntityManager.shared.add(troop)
                troops.append(troop)
            }
        }
          // Inimigos
        let basePosition = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero
          let enemyPositions = [
              CGPoint(x: basePosition.x - 50, y: basePosition.y),
              CGPoint(x: basePosition.x - 60, y: basePosition.y - 10),
              CGPoint(x: basePosition.x - 120, y: basePosition.y + 90)
          ]
        self.troops += enemyPositions.map { addTroop(at: $0, team: .moon) }
        
        
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
        releaseButton = CommandButton(position: Position.releaseButton(size: self.size), name: "R", color: .blue)
        releaseButton.onTouch = { [weak self] in
            self?.aimingSystem?.startAiming()
        }
        releaseButton.toggleCommand(value: false)
        camera?.addChild(releaseButton)
    }
}

