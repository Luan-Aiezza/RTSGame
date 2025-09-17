// GameScene+Setup.swift
import SpriteKit
import GameplayKit
import BehindGameKit

extension GameScene {
    func setupInputControllerIfNeeded() {
        if commandController == nil {
            commandController = AdaptedVirtualController(scene: self, color: .red)
        }
    }
    
    func configureScene(with sceneConfiguration: SceneConfiguration) {
        self.sceneConfiguration = sceneConfiguration
        setupNexus()
        setupInhibitors()
        setupSpawners()
        WaveManager.shared.setupWaves()
    }
    
    private func setupNexus() {
        if let node = childNode(withName: "Nexus") as? SKSpriteNode {
            let nexus = NexusEntity(node: node)
            
            // Adiciona o indicador de ataque
            nexus.addComponent(IndicatorAttackComponent())
            
            nexus.onDestroyed = { [weak self] in
                self?.handleDefeat()
            }
            
            SKEntityManager.shared.add(nexus)
            
            self.userData = self.userData ?? NSMutableDictionary()
            self.userData?["Nexus"] = nexus
        } else {
            print("Node 'Nexus' não encontrado na cena!")
        }
    }
    
    private func setupInhibitors() {
        for name in sceneConfiguration!.inhibitors {
            if let node = childNode(withName: name) as? SKSpriteNode {
                let inhibitor = InhibitorEntity(node: node)
                // Adiciona o indicador de ataque
                inhibitor.addComponent(IndicatorAttackComponent())
                
                SKEntityManager.shared.add(inhibitor)
            } else {
                print("Node '\(name)' não encontrado na cena!")
            }
        }
    }
    
    private func setupSpawners() {
        WaveManager.shared.scene = self
        for name in sceneConfiguration!.spawners {
            if let node = childNode(withName: name) as? SKSpriteNode {
                // Passa a cena para o SpawnEntity
                let spawner = SpawnEntity(node: node)
                print("Spawn Position \(node.position)")
                SKEntityManager.shared.add(spawner)
            } else {
                print("Node '\(name)' não encontrado na cena!")
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
        // Garante que o novo player tenha o observer de morte
        observePlayerDeath()
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
    
    func setupUI() {
        self.troopControlSystem = TroopControlSystem(scene: self, targetEntity: controlledEntity)
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
        releaseButton = CommandButton(position: Position.releaseButton(size: self.size), name: "", color: .systemRed)
        releaseButton.onTouch = { [weak self] in
            self?.aimingSystem?.startAiming()
        }
        releaseButton.toggleCommand(value: false)
        camera?.addChild(releaseButton)
    }
}
