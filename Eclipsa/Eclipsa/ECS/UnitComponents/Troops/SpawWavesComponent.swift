import SpriteKit
import GameplayKit
import BehindGameKit

public class SpawnerWaveComponent: GKComponent {
    
    // MARK: - Configuração
    private weak var scene: GameScene?
    private var spawnPoints: [CGPoint] = []
    private weak var nexusTarget: NexusEntity?
    
    private var tempoRestante: TimeInterval = 0
    private var numeroWave: Int = 0
    
    public var intervaloEntreWaves: TimeInterval
    public var pisoTropas: Int
    public var limiteTropas: Int
    public var crescimentoPorWave: Int
    public var tipoDeTropa: TroopType
    public var maximoWaves: Int
    
    public enum TroopType {
        case mage
        case knight
    }
    
    // MARK: - Init
    init(
        scene: GameScene,
        intervaloEntreWaves: TimeInterval = 10,
        pisoTropas: Int = 2,
        limiteTropas: Int = 12,
        crescimentoPorWave: Int = 2,
        tipoDeTropa: TroopType = .mage,
        maximoWaves: Int = 5
    ) {
        self.scene = scene
        self.intervaloEntreWaves = intervaloEntreWaves
        self.pisoTropas = pisoTropas
        self.limiteTropas = limiteTropas
        self.crescimentoPorWave = crescimentoPorWave
        self.tipoDeTropa = tipoDeTropa
        self.maximoWaves = maximoWaves
        super.init()
        
        setupSpawnPoints()
        setupNexusTarget()
        tempoRestante = intervaloEntreWaves
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Setup
    private func setupSpawnPoints() {
        guard let scene = scene else { return }
        var index = 1
        while let node = scene.childNode(withName: "Spawn_\(index)") {
            spawnPoints.append(node.position)
            index += 1
        }
        if spawnPoints.isEmpty {
            print("⚠️ Nenhum Spawn_X encontrado na cena!")
        }
    }
    
    private func setupNexusTarget() {
        guard let scene = scene else { return }
        if let nexus = scene.userData?["Nexus"] as? NexusEntity {
            nexusTarget = nexus
        } else {
            print("Nexus não encontrado para SpawnerWaveComponent")
        }
    }
    
    // MARK: - Update
    public override func update(deltaTime seconds: TimeInterval) {
        guard scene != nil else { return }
        guard !spawnPoints.isEmpty, nexusTarget != nil else { return }
        
        guard numeroWave < maximoWaves else { return }
        
        tempoRestante -= seconds
        if tempoRestante <= 0 {
            gerarWave()
            tempoRestante = intervaloEntreWaves
        }
    }
    
    // MARK: - Geração
    private func gerarWave() {
        guard let scene = scene else { return }
        guard let nexusTarget = nexusTarget else { return }
        
        numeroWave += 1
        guard numeroWave <= maximoWaves else { return }
        
        let quantidade = min(pisoTropas + (numeroWave - 1) * crescimentoPorWave, limiteTropas)
        
        print("🌑 Gerando wave \(numeroWave)/\(maximoWaves) com \(quantidade) tropas de \(tipoDeTropa)")
        
        for i in 0..<quantidade {
            let spawnIndex = i % spawnPoints.count
            let spawnPoint = spawnPoints[spawnIndex]
            
            // Cria a tropa conforme o tipo (por enquanto ambos usam TroopEntity base)
            let troop: TroopEntity
            switch tipoDeTropa {
            case .mage:
                troop = TroopFactory.makeRanged(team: .moon, allTroops: { [weak scene] in
                    return Array(scene?.troops ?? [])
                })
            case .knight:
                troop = TroopFactory.makeMelee(team: .moon, allTroops: { [weak scene] in
                    return Array(scene?.troops ?? [])
                })
            }
            
            if let node = troop.component(ofType: GKSKNodeComponent.self)?.node {
                node.position = spawnPoint
                scene.addChild(node)
            }
            
            // Sempre adiciona AgentComponent primeiro
            if troop.component(ofType: AgentComponent.self) == nil,
               let node = troop.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
                troop.addComponent(AgentComponent(node: node))
            }
            
            // Agora adiciona Behavior apontando para o Nexus (já está desopcionalizado no guard acima)
            let behavior = TroopBehaviorComponent(
                troop: troop,
                target: nexusTarget,
                allTroops: { [weak scene] in
                    return Set(scene?.troops ?? [])
                }
            )
            troop.addComponent(behavior)
            
            PhysicsSystem.setupTroopPhysics(for: troop)
            SKEntityManager.shared.add(troop)
        }
    }
}
