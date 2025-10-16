//
//  MultiplayerGameScene+MatchDelegate.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/10/25.
//

import GameKit
import BehindGameKit

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
                if self.remotePlayerEntity == nil {
                    let remote = UnitEntity(team: self.remoteTeam)
                    SKEntityManager.shared.add(remote)
                    if remote.spriteNode.parent == nil { self.addChild(remote.spriteNode) }
                    self.remotePlayerEntity = remote
                }
                self.remoteTargetPosition = CGPoint(x: CGFloat(fx), y: CGFloat(fy))
                self.remoteTargetRotation = CGFloat(frot)
                if let sm = self.remotePlayerEntity?.component(ofType: StateMachineComponent.self) {
                    if anim == 1 { sm.stateMachine.enter(WalkingState.self) } else { sm.stateMachine.enter(IdleState.self) }
                }
            }
            
            // Em MultiplayerGameScene+MatchDelegate.swift
            
        case .troopSpawn:
            // Expected: [type][ID][x][y][team][troopType]
            let expected = 1 + 4 + 4 + 4 + 1 + 1 // Tamanho atualizado
            guard data.count >= expected else { return }
            
            var offset = 1
            func readUInt32() -> UInt32 { defer { offset += 4 }; return data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) } }
            func readFloat() -> Float { defer { offset += 4 }; return data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: Float.self) } }
            
            let id = readUInt32()
            let fx = readFloat()
            let fy = readFloat()
            let teamByte = data[offset]; offset += 1
            let troopTypeByte = data[offset]; offset += 1 // <-- LENDO O NOVO BYTE
            
            let team: Team = (teamByte == 0) ? .sun : .moon
            guard let troopType = TroopType(rawValue: troopTypeByte) else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.troopNodesByID[id] != nil { return }
                
                let point = CGPoint(x: CGFloat(fx), y: CGFloat(fy))
                
                // Cria a tropa remota usando o mesmo método centralizado
                let troop = TroopEntity.createTroop(type: troopType, at: point, team: team)
                
                SKEntityManager.shared.add(troop)
                if let comp = troop.component(ofType: GKSKNodeComponent.self) {
                    self.troopNodesByID[id] = comp
                    self.troopTeamByID[id] = team
                    if comp.node.parent == nil { self.addChild(comp.node) }
                }
            }

        case .troopRemove:
            // Expected size: 1 + 4
            let expected = 1 + 4
            guard data.count >= expected else { return }
            var offset = 1
            let id: UInt32 = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let comp = self.troopNodesByID[id] {
                    comp.node.removeFromParent()
                    self.troopNodesByID.removeValue(forKey: id)
                    self.troopTeamByID.removeValue(forKey: id)
                }
            }

        case .troopHealth:
            // [type][UInt32 id][Float32 health]
            let expected = 1 + 4 + 4
            guard data.count >= expected else { return }
            var offset = 1
            let id: UInt32 = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) }
            offset += 4
            let health: Float = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: Float.self) }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // If your TroopEntity has a HealthComponent, update it here
                if let comp = self.troopNodesByID[id],
                   let entity = comp.entity as? TroopEntity,
                   let healthComp = entity.component(ofType: HealthComponent.self) {
                    healthComp.currentHealth = Int(CGFloat(health))
                    if healthComp.currentHealth <= 0 {
                        comp.node.removeFromParent()
                        self.troopNodesByID.removeValue(forKey: id)
                        self.troopTeamByID.removeValue(forKey: id)
                    }
                }
            }

        case .troopAttack:
            // [type][UInt32 attackerID][UInt32 targetID]
            let expected = 1 + 4 + 4
            guard data.count >= expected else { return }
            var offset = 1
            let attackerID: UInt32 = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) }
            offset += 4
            let targetID: UInt32 = data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // If you have an attack system, you could trigger a local visual/effect here
                _ = attackerID; _ = targetID
            }
            
            // Em MultiplayerGameScene+MatchDelegate.swift
            
            // Adicione este novo case dentro do switch
        case .troopState:
            // Expected: [type][UInt32 id][Float32 x][Float32 y]
            let expected = 1 + 4 + 4 + 4
            guard data.count >= expected else { return }
            
            var offset = 1
            func readUInt32() -> UInt32 { defer { offset += 4 }; return data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: UInt32.self) } }
            func readFloat() -> Float { defer { offset += 4 }; return data.subdata(in: offset..<(offset+4)).withUnsafeBytes { $0.load(as: Float.self) } }
            
            let id = readUInt32()
            let x = readFloat()
            let y = readFloat()
            
            DispatchQueue.main.async { [weak self] in
                // Não movemos a tropa diretamente. Apenas definimos o "alvo"
                // para onde ela deve se mover suavemente no update().
                self?.remoteTroopTargetPositions[id] = CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
    }
}
