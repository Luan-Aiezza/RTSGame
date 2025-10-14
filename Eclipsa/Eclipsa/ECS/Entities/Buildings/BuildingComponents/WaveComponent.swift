//
//  WaveComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 12/09/25.
//

import GameplayKit
import SpriteKit
import BehindGameKit


struct WaveConfiguration {
    let waveNumber: Int
    let duration: TimeInterval
    let spawnInterval: TimeInterval
    let maxTroopsPerBuilding: Int
    let difficultyMultiplier: Float
}

class WaveManager: NSObject {
    static let shared = WaveManager()

    private enum WaveState {
        case idle
        case running
        case paused
        case completed
    }

    private var state: WaveState = .idle
    private var activeTimer: Timer?
    private var remainingTime: TimeInterval?
    private var enemyBuildings: [GKEntity] = []
    private var currentSpawnerIndex: Int = 0
    
    // MARK: - Configuração fixa (loop infinito)
    private let spawnInterval: TimeInterval = 20.0   // intervalo global
    private let troopsPerGroup: Int = 3              // tamanho do grupo fixo

    var scene: GameScene?

    private override init() {
        super.init()
    }

    // MARK: - Controle principal
    func startWaveSystem() {
        guard state == .idle else {
            print("WaveManager: já está rodando")
            return
        }
        state = .running
        currentSpawnerIndex = 0
        scheduleNextSpawn()
        print("WaveManager iniciado em loop infinito")
    }

    func stopWaveSystem() {
        state = .completed
        activeTimer?.invalidate()
        activeTimer = nil
        print("WaveManager parado")
    }

    // MARK: - Spawn sequencial
    private func scheduleNextSpawn() {
        guard state == .running,
              !enemyBuildings.isEmpty,
              let config = scene?.sceneConfiguration else { return }

        // ⏳ sempre espera o intervalo antes de chamar o próximo da fila
        activeTimer = Timer.scheduledTimer(withTimeInterval: config.spawnInterval,
                                           repeats: false) { [weak self] _ in
            self?.spawnFromNextBuilding()
        }
    }



    private func spawnFromNextBuilding() {
        guard !enemyBuildings.isEmpty,
              let config = scene?.sceneConfiguration else { return }

        // Pega o spawner atual da fila
        let building = enemyBuildings[currentSpawnerIndex]
        if let spawner = building.component(ofType: TroopSpawnerComponent.self) {
            spawner.spawnGroup(size: config.troopsPerGroup)
            print("Spawner \(currentSpawnerIndex) liberou \(config.troopsPerGroup) tropas")
        }

        // Passa a vez para o próximo
        currentSpawnerIndex = (currentSpawnerIndex + 1) % enemyBuildings.count

        // Agenda o próximo da fila
        scheduleNextSpawn()
    }

    // MARK: - Pause / Resume
    func pauseWaveSystem() {
        guard state == .running, let timer = activeTimer else {
            print("WaveManager: nenhum timer ativo para pausar")
            return
        }

        remainingTime = timer.fireDate.timeIntervalSinceNow
        timer.invalidate()
        activeTimer = nil
        state = .paused
        print("WaveManager pausado. Restante: \(remainingTime ?? 0)s")
    }

    func resumeWaveSystem() {
        guard state == .paused, let remaining = remainingTime, remaining > 0 else {
            print("WaveManager: nada para retomar")
            return
        }

        state = .running
        activeTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
            self?.spawnFromNextBuilding()
        }
        remainingTime = nil
        print("WaveManager retomado")
    }

    // MARK: - Reset
    func resetWaveSystem() {
        stopWaveSystem()
        state = .idle
        remainingTime = nil
        currentSpawnerIndex = 0
        print("WaveManager resetado")
    }

    // MARK: - Registro dos spawners
    func registerEnemyBuilding(_ building: GKEntity) {
        enemyBuildings.append(building)
    }
    
    func startInfiniteLoop(after delay: TimeInterval = 0, scene: GameScene) {
        guard state == .idle else { return }
        self.scene = scene
        self.state = .running
        self.currentSpawnerIndex = 0
        
        if delay > 0 {
            scene.run(.wait(forDuration: delay)) { [weak self] in
                self?.scheduleNextSpawn()
            }
        } else {
            scheduleNextSpawn()
        }
    }

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
    
    func spawnGroup(size: Int) {
        for _ in 0..<size {
            spawnTroop()
        }
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
        guard let building = entity,
              let buildingSprite = building.component(ofType: GKSKNodeComponent.self)?.node else {
            return
        }

        // Cria a tropa
        let troop = createTroop(at: buildingSprite.position)

        if let troop = troop {
            PhysicsSystem.setupTroopPhysics(for: troop)
            SKEntityManager.shared.add(troop)
            print("Tropa spawnada em \(buildingSprite.position)")
        }
    }
    
    private func createTroop(at position: CGPoint) -> TroopEntity? {
        let troop: TroopEntity
        
        // Gera um número de 0.0 até 1.0
        let chance = Double.random(in: 0...1)
        
        if chance <= 0.7 { // 70% ranged
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
