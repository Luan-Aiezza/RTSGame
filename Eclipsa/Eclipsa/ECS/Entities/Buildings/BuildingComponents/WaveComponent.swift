//
//  WaveComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 12/09/25.
//

import GameplayKit
import SpriteKit
import BehindGameKit

class WaveManager: NSObject {
    static let shared = WaveManager()
    
    private var currentWave = 0
    private var waveConfigurations: [WaveConfiguration] = []
    private var isWaveActive = false
    private var waveTimer: Timer?
    private var enemyBuildings: [GKEntity] = []
    
    // Intervalo fixo entre waves (40 segundos)
    private let waveCooldownInterval: TimeInterval = 20.0
    
    var scene: GameScene?
    
    private override init() {
        super.init()
    }
    
    func setupWaves(after interval: TimeInterval = 10.0) {
        scene?.run(.wait(forDuration: interval)) { [weak self] in
            self?.scene?.hidePhaseOverlay()
            self?.waveConfigurations = (self?.scene?.sceneConfiguration!.waveConfig)!
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                WaveManager.shared.startWaveSystem()
            }
        }
    }
    
    func startWaveSystem() {
        // Inicia a primeira wave imediatamente
        startNextWave()
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
        
        // Timer para encerrar a wave (baseado na duração da wave)
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
        
        print("Wave \(currentWave) finalizada. Próxima wave em \(waveCooldownInterval) segundos.")
        
        // Timer fixo de 40 segundos para a próxima wave
        Timer.scheduledTimer(withTimeInterval: waveCooldownInterval, repeats: false) { [weak self] _ in
            self?.startNextWave()
        }
    }
    
    private func completeAllWaves() {
        print("Todas as waves foram completadas!")
        // Implementar lógica de fim de jogo
        // Você pode decidir se quer reiniciar as waves ou finalizar o jogo
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
    
    // Método para pausar o sistema de waves
    func pauseWaveSystem() {
        waveTimer?.invalidate()
        for building in enemyBuildings {
            if let spawner = building.component(ofType: TroopSpawnerComponent.self) {
                spawner.stopWave()
            }
        }
        isWaveActive = false
    }
    
    // Método para resetar o sistema de waves
    func resetWaveSystem() {
        pauseWaveSystem()
        currentWave = 0
        isWaveActive = false
    }
}

// MARK: - Wave Configuration
struct WaveConfiguration {
    let waveNumber: Int
    let duration: TimeInterval // Duração de quanto tempo a wave fica ativa gerando tropas
    let spawnInterval: TimeInterval // Intervalo entre spawns de tropas
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
        troopsSpawned = 0 // Reset do contador para a próxima wave
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
