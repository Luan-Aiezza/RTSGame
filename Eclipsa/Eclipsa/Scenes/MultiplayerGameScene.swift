//
//  MultiplayerGameScene.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import SpriteKit
import GameKit
import BehindGameKit
import GameplayKit
import Combine

final class MultiplayerGameScene: GameScene {
    private(set) var match: GKMatch?
    public var localTeam: Team = .sun
    public var remoteTeam: Team = .moon
    
    public var remotePlayerEntity: UnitEntity?
    
    // Identificador para sincronização
    public var localPlayerID: String = GKLocalPlayer.local.gamePlayerID
    public var remotePlayer: GKPlayer?

    // MARK: - Init
    init(size: CGSize, match: GKMatch) {
        self.match = match
        super.init(size: size)
        scaleMode = .resizeFill
        match.delegate = self
    }

    /// Inicializador usado quando a cena é carregada via .sks ou storyboard.
    /// Evita crash ao usar `SKScene(fileNamed:)` ou carregamento automático do GameKit.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
    }

    // MARK: - Setup após criação
    /// Deve ser chamado logo após a cena ser criada, caso o `match` ainda não exista.
    func configure(with match: GKMatch) {
        self.match = match
        match.delegate = self
        configureTeams()
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        print("🕹️ MultiplayerGameScene iniciada")

        // Se ainda não há match, espere até ser configurado
        guard let match = match else {
            print("⚠️ Match ainda não configurado. Chame `configure(with:)` antes de apresentar a cena.")
            return
        }

        // 1️⃣ Define os times com base na ordem de conexão
        configureTeams()
        
        // 2️⃣ Carrega conteúdo visual do arquivo .sks (se existir)
        if let path = Bundle.main.path(forResource: "MultiplayerGameScene", ofType: "sks"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SKScene.self, from: data) {
            for node in unarchived.children {
                addChild(node)
            }
        }
        
        // 3️⃣ Cria estruturas e entidades principais
        setupMultiplayerStructures()
        
        // 4️⃣ Cria jogadores locais e remotos
        setupPlayers()
        
        // 5️⃣ Configura interface e câmera
        setupCamera()
        setupUI()
        setupRTSAiming()
        
        print("✅ MultiplayerGameScene pronta com times: \(localTeam) vs \(remoteTeam)")
    }
}

// MARK: - Team Configuration
extension MultiplayerGameScene {
    func configureTeams() {
        guard let match = match, match.players.count > 0 else { return }
        let sortedPlayers = ([GKLocalPlayer.local] + match.players).sorted { $0.gamePlayerID < $1.gamePlayerID }
        
        if sortedPlayers.first?.gamePlayerID == GKLocalPlayer.local.gamePlayerID {
            localTeam = .sun
            remoteTeam = .moon
        } else {
            localTeam = .moon
            remoteTeam = .sun
        }
        
        remotePlayer = match.players.first(where: { $0.gamePlayerID != GKLocalPlayer.local.gamePlayerID })
    }
}

// MARK: - Sync System
extension MultiplayerGameScene {
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        sendLocalPlayerState()
    }

    func sendLocalPlayerState() {
        guard let match = match,
              let playerNode = controlledEntity?.spriteNode else { return }
        
        let position = playerNode.position
        let data = try? JSONEncoder().encode(PlayerSyncData(
            playerID: localPlayerID,
            x: position.x,
            y: position.y
        ))
        
        if let data = data {
            try? match.sendData(toAllPlayers: data, with: .unreliable)
        }
    }
}

struct PlayerSyncData: Codable {
    let playerID: String
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Match Delegate
extension MultiplayerGameScene: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let info = try? JSONDecoder().decode(PlayerSyncData.self, from: data),
              let remoteNode = remotePlayerEntity?.spriteNode else { return }
        
        remoteNode.position = CGPoint(x: info.x, y: info.y)
    }
}

