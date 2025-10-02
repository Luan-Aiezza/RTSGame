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
    
    private enum WaveState {
        case idle
        case spawning(waveIndex: Int)
        case cooldown(nextWaveIndex: Int)
        case completed
    }
    
    private var state: WaveState = .idle
    private var activeTimer: Timer?
    private var remainingTime: TimeInterval?
    private var waveConfigurations: [WaveConfiguration] = []
    private var enemyBuildings: [GKEntity] = []
    
    // MARK: - Configuration
    private let waveCooldownInterval: TimeInterval = 10.0
    var scene: GameScene?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup
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
        guard case .idle = state else {
            print("WaveManager: Sistema já está ativo")
            return
        }
        startNextWave()
    }
    
    // MARK: - Wave Control
    private func startNextWave() {
        let currentWaveIndex: Int
        
        switch state {
        case .idle:
            currentWaveIndex = 0
        case .cooldown(let nextIndex):
            currentWaveIndex = nextIndex
        default:
            print("WaveManager: Tentativa de iniciar wave em estado inválido: \(state)")
            return
        }
        
        guard currentWaveIndex < waveConfigurations.count else {
            completeAllWaves()
            return
        }
        
        let waveConfig = waveConfigurations[currentWaveIndex]
        state = .spawning(waveIndex: currentWaveIndex)
        
        print("Wave \(currentWaveIndex + 1) INICIADA - Duração: \(waveConfig.duration)s")
        
        // Notifica buildings para começar spawn
        notifyBuildings(action: .start(waveConfig))
        
        // Agenda fim da wave
        scheduleTimer(duration: waveConfig.duration) { [weak self] in
            self?.endCurrentWave(waveIndex: currentWaveIndex)
        }
    }
    
    private func endCurrentWave(waveIndex: Int) {
        guard case .spawning(let currentIndex) = state, currentIndex == waveIndex else {
            print("WaveManager: Wave \(waveIndex) já foi encerrada ou estado inconsistente")
            return
        }
        
        print("Wave \(waveIndex + 1) FINALIZADA - Cooldown: \(waveCooldownInterval)s")
        
        // Para spawn em todos os buildings
        notifyBuildings(action: .stop)
        
        // Muda para cooldown
        let nextWaveIndex = waveIndex + 1
        state = .cooldown(nextWaveIndex: nextWaveIndex)
        
        // Agenda próxima wave
        scheduleTimer(duration: waveCooldownInterval) { [weak self] in
            self?.startNextWave()
        }
    }
    
    private func completeAllWaves() {
        state = .completed
        activeTimer?.invalidate()
        activeTimer = nil
        notifyBuildings(action: .stop)
        print("Todas as waves foram completadas!")
    }
    
    // MARK: - Building Management
    private enum BuildingAction {
        case start(WaveConfiguration)
        case stop
        case resume(WaveConfiguration)
    }
    
    private func notifyBuildings(action: BuildingAction) {
        for building in enemyBuildings {
            guard let spawner = building.component(ofType: TroopSpawnerComponent.self) else {
                continue
            }
            
            switch action {
            case .start(let config):
                spawner.startWave(config)
            case .stop:
                spawner.stopWave()
            case .resume(let config):
                spawner.resumeWave(waveConfig: config)
            }
        }
    }
    
    // MARK: - Timer Management
    private func scheduleTimer(duration: TimeInterval, completion: @escaping () -> Void) {
        activeTimer?.invalidate()
        activeTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            completion()
        }
    }
    
    // MARK: - Pause/Resume
    func pauseWaveSystem() {
        guard let timer = activeTimer else {
            print("WaveManager: Nenhum timer ativo para pausar")
            return
        }
        
        remainingTime = timer.fireDate.timeIntervalSinceNow
        timer.invalidate()
        activeTimer = nil
        
        notifyBuildings(action: .stop)
        
        print("Sistema pausado. Tempo restante: \(remainingTime ?? 0)s - Estado: \(state)")
    }
    
    func resumeWaveSystem() {
        guard let remaining = remainingTime, remaining > 0 else {
            print("WaveManager: Nenhum tempo restante para resumir")
            return
        }
        
        print("Sistema retomado. Restante: \(remaining)s - Estado: \(state)")
        
        switch state {
        case .spawning(let waveIndex):
            let waveConfig = waveConfigurations[waveIndex]
            notifyBuildings(action: .resume(waveConfig))
            
            scheduleTimer(duration: remaining) { [weak self] in
                self?.endCurrentWave(waveIndex: waveIndex)
            }
            
        case .cooldown:
            scheduleTimer(duration: remaining) { [weak self] in
                self?.startNextWave()
            }
            
        default:
            print("WaveManager: Estado inválido para resumir: \(state)")
        }
        
        remainingTime = nil
    }
    
    // MARK: - Reset
    func resetWaveSystem() {
        pauseWaveSystem()
        state = .idle
        remainingTime = nil
        print("Sistema resetado")
    }
    
    // MARK: - Public Getters
    func registerEnemyBuilding(_ building: GKEntity) {
        enemyBuildings.append(building)
    }
    
    func getCurrentWave() -> Int {
        switch state {
        case .spawning(let index), .cooldown(let index):
            return index + 1
        default:
            return 0
        }
    }
    
    func isCurrentlyInWave() -> Bool {
        if case .spawning = state {
            return true
        }
        return false
    }
}

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
    private var timeOffsetGeneration: TimeInterval
    
    
    var spawnOffset: CGPoint {
        let angle = Double.random(in: 0..<2*Double.pi)
        let radius = Double.random(in: 80...100)
        return CGPoint(x: (cos(angle) * radius).magnitude, y: sin(angle) * radius)
    }
    
    init(timeOffsetGeneration: Double) {
        let convertToTimeInterval = (timeOffsetGeneration / 5.0) - (timeOffsetGeneration / 10.5)
        
        self.timeOffsetGeneration = convertToTimeInterval
    
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
        
        let useTimer = verifyWaveTimer(configureTimer: waveConfig.spawnInterval, offsetTimer: timeOffsetGeneration)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: useTimer, repeats: true) { [weak self] _ in
            self?.spawnTroop()
        }
    }
    
    private func verifyWaveTimer(configureTimer: TimeInterval, offsetTimer: TimeInterval) -> TimeInterval{
        let convertedTimer = configureTimer - offsetTimer
        
        if convertedTimer < 1.2 {
            return 1.2
        }
        return convertedTimer
    }
    
    func stopWave() {
        spawnTimer?.invalidate()
        spawnTimer = nil
        currentWaveConfig = nil
        troopsSpawned = 0 // Reset do contador para a próxima wave
    }
    
    func resumeWave(waveConfig: WaveConfiguration) {
        currentWaveConfig = waveConfig
        dump(waveConfig)
        
        let useTimer = verifyWaveTimer(configureTimer: currentWaveConfig!.spawnInterval, offsetTimer: timeOffsetGeneration)
        print(useTimer)
        spawnTimer = Timer.scheduledTimer(withTimeInterval: useTimer, repeats: true) { [weak self] _ in
            self?.spawnTroop()
        }
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
        let troop: TroopEntity
        
        // Gera um número de 0.0 até 1.0
        let chance = Double.random(in: 0...1)
        
        if chance < 0.8 { // 70% ranged
            troop = TroopFactory.makeRanged(team: .moon) {
                return []
            }
        } else { // 30% melee
            troop = TroopFactory.makeMelee(team: .moon) {
                return []
            }
        }
        
        // Define posição com offset
        troop.component(ofType: GKSKNodeComponent.self)?.node.position = position + spawnOffset
        
        // Configura comportamento e alvo
        guard let nexusTarget = scene?.userData?["Nexus"] as? NexusEntity else { return nil }
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
