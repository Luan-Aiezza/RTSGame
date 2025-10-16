//
//  MultiplayerGameScene+Sync.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/10/25.
//

// MARK: - Team Configuration
import GameKit
import BehindGameKit

fileprivate let MultiplayerGameScene_SendInterval: TimeInterval = 1.0 / 30.0
fileprivate var MultiplayerGameScene_LastSentTime: TimeInterval = 0
fileprivate let MultiplayerGameScene_TroopSendInterval: TimeInterval = 1.0 / 20.0 // 20Hz
fileprivate var MultiplayerGameScene_LastTroopSentTime: TimeInterval = 0

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
        case troopSpawn  = 0x02
        case troopRemove = 0x03
        case troopHealth = 0x04
        case troopAttack = 0x05
        case troopState  = 0x06 // <-- NOVO: Para posição, rotação, etc.
    }
    
    private var playerNode: SKNode? { controlledEntity?.spriteNode }
    
    // Dicionário para suavizar o movimento das tropas remotas
    public var remoteTroopTargetPositions: [UInt32: CGPoint] {
        get {
            // Use SKNode.userData to store per-instance state since extensions can't add stored properties
            if let dict = self.userData?["remoteTroopTargetPositions"] as? [UInt32: CGPoint] {
                return dict
            } else {
                let initial: [UInt32: CGPoint] = [:]
                if self.userData == nil { self.userData = NSMutableDictionary() }
                self.userData?["remoteTroopTargetPositions"] = initial
                return initial
            }
        }
        set {
            if self.userData == nil { self.userData = NSMutableDictionary() }
            self.userData?["remoteTroopTargetPositions"] = newValue
        }
    }
    
    // Rate limit to avoid flooding the network - moved to top-level fileprivate variables
    
    // Timer para envio do estado das tropas (um pouco menos frequente que o do jogador) - moved to top-level fileprivate variables
    
    // ATUALIZE sua função update(_:)
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Envio do estado do jogador (30Hz)
        if currentTime - MultiplayerGameScene_LastSentTime >= MultiplayerGameScene_SendInterval {
            MultiplayerGameScene_LastSentTime = currentTime
            sendLocalPlayerState()
        }
        
        // NOVO: Envio do estado das tropas (20Hz)
        if currentTime - MultiplayerGameScene_LastTroopSentTime >= MultiplayerGameScene_TroopSendInterval {
            MultiplayerGameScene_LastTroopSentTime = currentTime
            sendOwnedTroopStates()
        }
        
        checkAndSyncTroopDeaths()
        
        // Suavização do jogador remoto
        if let remote = remotePlayerEntity, let targetPos = remoteTargetPosition {
            let node = remote.spriteNode
            let alpha: CGFloat = 0.2
            node.position = CGPoint(x: lerp(node.position.x, targetPos.x, t: alpha),
                                    y: lerp(node.position.y, targetPos.y, t: alpha))
        }
        // ... suavização da rotação do jogador ...
        
        // NOVO: Suavização das tropas remotas
        for (id, targetPosition) in remoteTroopTargetPositions {
            if let node = troopNodesByID[id]?.node {
                let alpha: CGFloat = 0.2
                node.position = CGPoint(x: lerp(node.position.x, targetPosition.x, t: alpha),
                                        y: lerp(node.position.y, targetPosition.y, t: alpha))
            }
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
        
        // ✅ LÓGICA CORRIGIDA
        // Conectamos callbacks apenas para as tropas que este jogador possui.
        if team == localTeam {
            if let healthComponent = troop.component(ofType: HealthComponent.self) {
                
                // O onHealthChanged está correto para sincronizar o dano.
                // O primeiro parâmetro do closure é a vida atual, o segundo é a vida máxima.
                healthComponent.onHealthChanged = { [weak self] currentHealth, maxHealth in
                    self?.sendTroopHealth(id: id, health: Float(currentHealth))
                }
                
                // O callback de morte é agora tratado pelo `checkAndSyncTroopDeaths`,
                // então não precisamos de um `onDie` aqui.
            }
        }
        
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
    
    // Adicione esta nova função de envio
    func sendOwnedTroopStates() {
        guard let match = match else { return }
        
        // Itera apenas nas tropas que este jogador "possui"
        for (id, team) in troopTeamByID where team == localTeam {
            guard let node = troopNodesByID[id]?.node else { continue }
            
            var data = Data()
            data.append(PacketType.troopState.rawValue)
            
            var troopID = id
            var x = Float(node.position.x)
            var y = Float(node.position.y)
            
            withUnsafeBytes(of: &troopID) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &y) { data.append(contentsOf: $0) }
            
            // Use .unreliable para dados de posição. Se um pacote se perder,
            // o próximo corrigirá a posição sem causar atrasos na rede.
            try? match.sendData(toAllPlayers: data, with: .unreliable)
        }
    }
    
    private func checkAndSyncTroopDeaths() {
        // Itera apenas sobre as tropas que este jogador "possui"
        for (id, team) in troopTeamByID where team == localTeam {
            
            // 1. Se já enviamos a mensagem de morte, ignore.
            if deathMessageSentTroopIDs.contains(id) {
                continue
            }
            
            // 2. Verifique se a tropa entrou no estado de morte
            if let entity = troopNodesByID[id]?.entity,
               let stateMachine = entity.component(ofType: StateMachineComponent.self)?.stateMachine,
               stateMachine.currentState is TroopDieState {
                
                // 3. Se entrou, envie a mensagem de remoção para o oponente
                print("Sync: Enviando morte para a tropa ID \(id)")
                sendTroopRemove(identifier: id)
                
                // 4. Marque que a mensagem foi enviada para não repetir
                deathMessageSentTroopIDs.insert(id)
            }
        }
    }
    
}
