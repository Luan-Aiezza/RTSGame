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
        
        // Inicia o loop infinito de spawn
        if self.name == "GameScene_0" {
            // caso queira atraso especial só na primeira fase
            WaveManager.shared.startInfiniteLoop(after: 25, scene: self)
        } else {
            WaveManager.shared.startInfiniteLoop(scene: self)
        }
    }

    
    private func setupNexus() {
        if let node = childNode(withName: "Nexus") as? SKSpriteNode {
            let nexus = NexusEntity(node: node)
            
            // Adiciona o indicador de ataque
            nexus.addComponent(IndicatorAttackComponent())
            
            nexus.onDestroyed = { [weak self] in
                nexus.removeComponent(ofType: IndicatorAttackComponent.self)
                self?.handleDefeat()
                self?.pauseButtonDelegate?.showPauseButton()
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
                
                inhibitor.onDestroyed = { [weak inhibitor] in
                    inhibitor?.removeComponent(ofType: IndicatorAttackComponent.self)
                }
                
                SKEntityManager.shared.add(inhibitor)
            } else {
                print("Node '\(name)' não encontrado na cena!")
            }
        }
    }
    
    private func setupSpawners() {
        WaveManager.shared.scene = self
        
        // Conta total de spawners e registra callbacks de destruição
        var totalSpawners = 0
        var destroyedSpawners = 0
        
        for name in sceneConfiguration!.spawners {
            if let node = childNode(withName: name) as? SKSpriteNode {
                let spawner = SpawnEntity(node: node)
                if let last = name.last,
                   let number = Int(String(last)) {
                    configureSpawner(offSetNumber: number, entity: spawner)
                } else {
                    configureSpawner(offSetNumber: 1, entity: spawner)
                }
                print("Spawn Position \(node.position)")
                SKEntityManager.shared.add(spawner)
                
                totalSpawners += 1
                
                // Callback de destruição do spawner (mesma ideia do nexus.onDestroyed)
                spawner.onDestroyed = { [weak self] in
                    guard let self else { return }
                    destroyedSpawners += 1
                    // Se todos os spawners foram destruídos, declara vitória
                    if destroyedSpawners >= totalSpawners {
                        self.handleWin()
                    }
                }
            } else {
                print("Node '\(name)' não encontrado na cena!")
            }
            func configureSpawner(offSetNumber: Int, entity: SpawnEntity){
                let spawnerComponent = TroopSpawnerComponent(timeOffsetGeneration: Double(offSetNumber))
                spawnerComponent.setupWithScene(self)
                entity.addComponent(spawnerComponent)
                WaveManager.shared.registerEnemyBuilding(entity)
            }
        }
        
        // Caso especial: sem spawners, já considera vitória da fase (ou mantém como está, conforme game design)
        if totalSpawners == 0 {
            self.handleWin()
        }
    }
    
    func setupPlayer() {
        setupInputControllerIfNeeded()
        controlledEntity = UnitEntity(team: .sun)
        SKEntityManager.shared.add(controlledEntity)
        setupRTSAiming()
        
        controlledEntity.addComponent(AimControlComponent(delegate: aimingSystem!))
        controlledEntity.component(ofType: AimControlComponent.self)?
            .setupController(inputHandler: commandInput, virtualController: commandController)
        
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
        // 🔹 Inicializa o footprintManager só agora
        if let node = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node {
            footprintManager = FootprintManager(scene: self, player: node)
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
    
    func setupUI() {
        self.troopControlSystem = TroopControlSystem(scene: self, targetEntity: controlledEntity)
        setupCommandButton()
        setupReleaseButton()
    }
    
    private func setupCommandButton(){
        cancelButton = CommandButton(position: Position.cancelButton(size: self.size), name: "X")
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
