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
    // Simple binary protocol
    // [UInt8 type][Float32 x][Float32 y][Float32 rot][UInt8 anim]
    private enum PacketType: UInt8 { case playerState = 0x01 }

    private var playerNode: SKNode? { controlledEntity?.spriteNode }

    // Rate limit to avoid flooding the network
    private static let sendInterval: TimeInterval = 1.0 / 30.0
    private static var lastSentTime: TimeInterval = 0

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard currentTime - MultiplayerGameScene.lastSentTime >= MultiplayerGameScene.sendInterval else { return }
        MultiplayerGameScene.lastSentTime = currentTime
        sendLocalPlayerState()
    }

    func sendLocalPlayerState() {
        guard let match = match,
              let player = controlledEntity,
              let node = player.component(ofType: GKSKNodeComponent.self)?.node else { return }

        // Compose payload
        var data = Data()
        data.append(PacketType.playerState.rawValue)

        var x = Float(node.position.x)
        var y = Float(node.position.y)
        var rot = Float(node.zRotation)
        let isMoving = (player.moveComponent?.direction ?? .zero) != .zero
        let anim: UInt8 = isMoving ? 1 : 0

        withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &y) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &rot) { data.append(contentsOf: $0) }
        data.append(anim)

        do {
            try match.sendData(toAllPlayers: data, with: .unreliable)
        } catch {
            print("[Sync] Failed to send player state: \(error)")
        }
    }
}

// MARK: - Match Delegate
extension MultiplayerGameScene: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard data.count >= 1 else { return }
        guard let type = PacketType(rawValue: data[0]) else { return }

        switch type {
        case .playerState:
            // Expected size: 1 + 4 + 4 + 4 + 1
            let expected = 1 + 4 + 4 + 4 + 1
            guard data.count >= expected else { return }

            var offset = 1
            func readFloat() -> Float {
                let range = offset..<(offset+4)
                let value = data.subdata(in: range).withUnsafeBytes { $0.load(as: Float.self) }
                offset += 4
                return value
            }

            let fx = readFloat()
            let fy = readFloat()
            let frot = readFloat()
            let anim = data[offset]

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // Ensure remote entity exists
                if self.remotePlayerEntity == nil {
                    let remote = UnitEntity(team: self.remoteTeam)
                    SKEntityManager.shared.add(remote)
                    if remote.spriteNode.parent == nil { self.addChild(remote.spriteNode) }
                    self.remotePlayerEntity = remote
                }
                guard let remote = self.remotePlayerEntity,
                      let node = remote.component(ofType: GKSKNodeComponent.self)?.node else { return }

                // Update transform
                node.position = CGPoint(x: CGFloat(fx), y: CGFloat(fy))
                node.zRotation = CGFloat(frot)

                // Update simple animation state
                if let sm = remote.component(ofType: StateMachineComponent.self) {
                    if anim == 1 {
                        sm.stateMachine.enter(WalkingState.self)
                    } else {
                        sm.stateMachine.enter(IdleState.self)
                    }
                }
            }
        }
    }
}
