//
//  WaveComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 12/09/25.
//
import GameplayKit

import GameplayKit
import SpriteKit
import BehindGameKit

// MARK: - Wave Manager
class WaveManager: NSObject {
    static let shared = WaveManager()
    
    private var currentWave = 0
    private var waveConfigurations: [WaveConfiguration] = []
    private var isWaveActive = false
    private var waveTimer: Timer?
    private var enemyBuildings: [GKEntity] = []
    
    var scene: GameScene?
    
    private override init() {
        super.init()
        setupWaves()
    }
    
    private func setupWaves() {
        // Configuração das waves - customize conforme necessário
        waveConfigurations = [
            WaveConfiguration(
                waveNumber: 1,
                duration: 30.0,
                spawnInterval: 2.0,
                maxTroopsPerBuilding: 2,
                difficultyMultiplier: 1.0
            ),
            WaveConfiguration(
                waveNumber: 2,
                duration: 45.0,
                spawnInterval: 1.8,
                maxTroopsPerBuilding: 3,
                difficultyMultiplier: 1.2
            ),
            WaveConfiguration(
                waveNumber: 3,
                duration: 60.0,
                spawnInterval: 1.5,
                maxTroopsPerBuilding: 4,
                difficultyMultiplier: 1.5
            )
        ]
    }
    
    func startNextWave() {
        guard currentWave < waveConfigurations.count else {
            // Todas as waves foram completadas
            completeAllWaves()
            return
        }
        
        let waveConfig = waveConfigurations[currentWave]
        isWaveActive = true
        currentWave += 1
        
        print("Iniciando Wave \(currentWave)")
        
        // Notifica todas as construções inimigas sobre a nova wave
        for building in enemyBuildings {
            if let spawner = building.component(ofType: TroopSpawnerComponent.self) {
                spawner.startWave(waveConfig)
            }
        }
        
        // Timer para encerrar a wave
        waveTimer = Timer.scheduledTimer(withTimeInterval: waveConfig.duration, repeats: false) { [weak self] _ in
            self?.endCurrentWave()
        }
    }
    
    private func endCurrentWave() {
        isWaveActive = false
        waveTimer?.invalidate()
        
        // Para o spawn de tropas em todas as construções
        for building in enemyBuildings {
            if let spawner = building.component(ofType: TroopSpawnerComponent.self) {
                spawner.stopWave()
            }
        }
        
        print("Wave \(currentWave) finalizada")
        
        // Delay antes da próxima wave
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.startNextWave()
        }
    }
    
    private func completeAllWaves() {
        print("Todas as waves foram completadas!")
        // Implementar lógica de fim de jogo
    }
    
    func registerEnemyBuilding(_ building: GKEntity) {
        enemyBuildings.append(building)
    }
    
    func getCurrentWave() -> Int {
        return currentWave
    }
    
    func isCurrentlyInWave() -> Bool {
        return isWaveActive
    }
}

// MARK: - Wave Configuration
struct WaveConfiguration {
    let waveNumber: Int
    let duration: TimeInterval
    let spawnInterval: TimeInterval
    let maxTroopsPerBuilding: Int
    let difficultyMultiplier: Float
}

class TroopSpawnerComponent: GKComponent {
    private var spawnTimer: Timer?
    private var currentWaveConfig: WaveConfiguration?
    private var troopsSpawned = 0
    private weak var scene: GameScene?
    
    var spawnOffset: CGPoint {
        let angle = Double.random(in: 0..<2*Double.pi)
        let radius = Double.random(in: 80...100)
        return CGPoint(x: (cos(angle) * radius).magnitude, y: sin(angle) * radius)
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupWithScene(_ scene: GameScene) {
        self.scene = scene
    }
    
    func startWave(_ waveConfig: WaveConfiguration) {
        currentWaveConfig = waveConfig
        troopsSpawned = 0
        
        // Inicia o timer de spawn
        spawnTimer = Timer.scheduledTimer(withTimeInterval: waveConfig.spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnTroop()
        }
    }
    
    func stopWave() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        currentWaveConfig = nil
    }
    
    private func spawnTroop() {
        guard let waveConfig = currentWaveConfig,
              troopsSpawned < waveConfig.maxTroopsPerBuilding,
              let building = entity,
              let buildingSprite = building.component(ofType: GKSKNodeComponent.self)?.node else {
            return
        }
        
        // Cria a tropa
        let troop = createTroop(at: buildingSprite.position)
        
        // Adiciona a tropa à cena
//        if let troopSprite = troop?.component(ofType: GKSKNodeComponent.self)?.node {
//            scene?.addChild(troopSprite)
//        }
        PhysicsSystem.setupTroopPhysics(for: troop!)
        SKEntityManager.shared.add(troop!)
        troopsSpawned += 1
    }
    
    private func createTroop(at position: CGPoint) -> TroopEntity? {
        let troop = TroopFactory.makeRanged(team: .moon) {
            return []
        }
        troop.component(ofType: GKSKNodeComponent.self)?.node.position = position + spawnOffset
        guard let nexusTarget = scene?.userData?["Nexus"] as? NexusEntity else { return nil}
        let behavior = TroopBehaviorComponent(
            troop: troop,
            target: nexusTarget,
            allTroops: { [weak scene] in
                return Set(scene?.troops ?? [])
            }
        )
        troop.addComponent(behavior)
        
        return troop
    }
}
