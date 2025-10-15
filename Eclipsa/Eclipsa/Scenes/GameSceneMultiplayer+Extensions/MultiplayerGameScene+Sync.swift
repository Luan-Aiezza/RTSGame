//
//  MultiplayerGameScene+Sync.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/10/25.
//

// MARK: - Team Configuration
import GameKit
import BehindGameKit

public enum TroopType: UInt8 {
    case melee = 0
    case ranged = 1
}

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
    // [UInt8 type][UInt32 id][Float32 x][Float32 y][UInt8 team] for troopSpawn
    // [UInt8 type][UInt32 id] for troopRemove
    // [UInt8 type][UInt32 id][Float32 health] for troopHealth
    // [UInt8 type][UInt32 attackerID][UInt32 targetID] for troopAttack
    // Adicione este enum no topo do arquivo

    // Apenas para referência, o seu enum PacketType ficará assim
    public enum PacketType: UInt8 {
        case playerState = 0x01
        // FORMATO NOVO: [type][ID][x][y][team][troopType]
        case troopSpawn  = 0x02
        case troopRemove = 0x03
        case troopHealth = 0x04
        case troopAttack = 0x05
    }

    private var playerNode: SKNode? { controlledEntity?.spriteNode }

    // Rate limit to avoid flooding the network
    private static let sendInterval: TimeInterval = 1.0 / 30.0
    private static var lastSentTime: TimeInterval = 0

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        // Send local state at 30Hz
        if currentTime - MultiplayerGameScene.lastSentTime >= MultiplayerGameScene.sendInterval {
            MultiplayerGameScene.lastSentTime = currentTime
            sendLocalPlayerState()
        }
        // Smooth remote player transform
        if let remote = remotePlayerEntity,
           let node = remote.component(ofType: GKSKNodeComponent.self)?.node,
           let targetPos = remoteTargetPosition {
            let alpha: CGFloat = 0.2 // smoothing factor
            node.position = CGPoint(x: lerp(node.position.x, targetPos.x, t: alpha),
                                    y: lerp(node.position.y, targetPos.y, t: alpha))
        }
        if let remote = remotePlayerEntity,
           let node = remote.component(ofType: GKSKNodeComponent.self)?.node,
           let targetRot = remoteTargetRotation {
            let alpha: CGFloat = 0.2
            node.zRotation = lerp(node.zRotation, targetRot, t: alpha)
        }
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

    // NOVA API para os botões chamarem
    func invokeTroop(type: TroopType) {
        // Define um ponto de spawn (ex: na frente do Nexus do jogador local)
        // Adapte este ponto conforme a necessidade do seu jogo.
        guard let playerNode = controlledEntity?.spriteNode else { return }
        let spawnPoint = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 50)
        
        // Chama a função de rede
        sendTroopSpawn(at: spawnPoint, team: self.localTeam, type: type)
    }

    // FUNÇÃO ATUALIZADA
    func sendTroopSpawn(at point: CGPoint, team: Team, type: TroopType) {
        guard let match = match else { return }
        
        let id = nextLocalTroopID
        nextLocalTroopID &+= 1
        
        // Cria a tropa localmente usando o novo método centralizado
        let troop = TroopEntity.createTroop(type: type, at: point, team: team)
        
        SKEntityManager.shared.add(troop)
        if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
            addChild(node)
        }
        if let comp = troop.component(ofType: GKSKNodeComponent.self) {
            troopNodesByID[id] = comp
            troopTeamByID[id] = team
        }
        
        // Envia o pacote com o novo formato
        var data = Data()
        data.append(PacketType.troopSpawn.rawValue)
        var vid = id
        var x = Float(point.x)
        var y = Float(point.y)
        let teamByte: UInt8 = (team == .sun) ? 0 : 1
        let troopTypeByte = type.rawValue // <-- NOVO

        withUnsafeBytes(of: &vid) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &y) { data.append(contentsOf: $0) }
        data.append(teamByte)
        data.append(troopTypeByte) // <-- ADICIONADO
        
        do {
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("[Sync] Failed to send troop spawn: \(error)")
        }
    }

    func sendTroopRemove(identifier: UInt32) {
        guard let match = match else { return }
        // Remove locally if we have it
        if let comp = troopNodesByID[identifier] {
            comp.node.removeFromParent()
            troopNodesByID.removeValue(forKey: identifier)
            troopTeamByID.removeValue(forKey: identifier)
        }
        var data = Data()
        data.append(PacketType.troopRemove.rawValue)
        var id = identifier
        withUnsafeBytes(of: &id) { data.append(contentsOf: $0) }
        do { try match.sendData(toAllPlayers: data, with: .reliable) } catch {
            print("[Sync] Failed to send troop remove: \(error)")
        }
    }

    func sendTroopHealth(id: UInt32, health: Float) {
        guard let match = match else { return }
        var data = Data()
        data.append(PacketType.troopHealth.rawValue)
        var vid = id
        var h = health
        withUnsafeBytes(of: &vid) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &h) { data.append(contentsOf: $0) }
        try? match.sendData(toAllPlayers: data, with: .reliable)
    }

    func sendTroopAttack(attackerID: UInt32, targetID: UInt32) {
        guard let match = match else { return }
        var data = Data()
        data.append(PacketType.troopAttack.rawValue)
        var a = attackerID
        var t = targetID
        withUnsafeBytes(of: &a) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &t) { data.append(contentsOf: $0) }
        try? match.sendData(toAllPlayers: data, with: .reliable)
    }
}
