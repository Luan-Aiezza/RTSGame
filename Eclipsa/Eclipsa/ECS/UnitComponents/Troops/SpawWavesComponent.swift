//
//  SpawnerWaveComponent.swift
//  Eclipsa
//
//  Criado por Assistant em 01/09/25.
//

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
        tipoDeTropa: TroopType = .mage
    ) {
        self.scene = scene
        self.intervaloEntreWaves = intervaloEntreWaves
        self.pisoTropas = pisoTropas
        self.limiteTropas = limiteTropas
        self.crescimentoPorWave = crescimentoPorWave
        self.tipoDeTropa = tipoDeTropa
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
            print("⚠️ Nexus não encontrado para SpawnerWaveComponent")
        }
    }
    
    // MARK: - Update
    public override func update(deltaTime seconds: TimeInterval) {
        guard let scene = scene else { return }
        guard !spawnPoints.isEmpty, nexusTarget != nil else { return }
        
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
        let quantidade = min(pisoTropas + (numeroWave - 1) * crescimentoPorWave, limiteTropas)
        
        print("🌑 Gerando wave \(numeroWave) com \(quantidade) tropas de \(tipoDeTropa)")
        
        for i in 0..<quantidade {
            let spawnIndex = i % spawnPoints.count
            let spawnPoint = spawnPoints[spawnIndex]
            
            let troop: TroopEntity
            switch tipoDeTropa {
            case .mage:
//                troop = TroopEntity(team: .moon, allTroops: { [weak scene] in
//                    return Array(scene?.troops ?? [])
//                    
//                })
                
                troop = TroopFactory.makeRanged(team: .moon, allTroops: { [weak scene] in
                    return Array(scene?.troops ?? [])
                })
            case .knight:
//                troop = TroopEntity(team: .moon, allTroops: { [weak scene] in
//                    return Array(scene?.troops ?? [])
//                })//Knight
                troop = TroopFactory.makeMelee(team: .moon, allTroops: { [weak scene] in
                    return Array(scene?.troops ?? [])
                })
            }
            
            if let node = troop.component(ofType: GKSKNodeComponent.self)?.node {
                node.position = spawnPoint
                scene.addChild(node)
            }
            
            if troop.component(ofType: TeamComponent.self)?.team == .moon,
               troop.component(ofType: AgentComponent.self) == nil,
               let node = troop.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
                troop.addComponent(AgentComponent(node: node))
            }
            
            PhysicsSystem.setupTroopPhysics(for: troop)
            SKEntityManager.shared.add(troop)
            
            // Configura o comportamento da tropa para atacar o Nexus
            if let behavior = troop.component(ofType: TroopBehaviorComponent.self) {
                behavior.setTarget(nexusTarget)
            } else {
                let behavior = TroopBehaviorComponent(
                    troop: troop,
                    target: nexusTarget,
                    allTroops: { [weak scene] in scene?.troops ?? [] }
                )
                troop.addComponent(behavior)
            }
        }
    }
}

