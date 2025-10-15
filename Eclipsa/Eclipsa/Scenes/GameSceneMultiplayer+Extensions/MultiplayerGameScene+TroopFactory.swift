//
//  MultiplayerGameScene+TroopFactory.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 15/10/25.
//

// Em um arquivo como TroopEntity.swift ou um novo arquivo de Factory

import GameplayKit

extension TroopEntity {
    // Método centralizado para criar qualquer tipo de tropa
    static func createTroop(
        type: TroopType,
        at position: CGPoint,
        team: Team
    ) -> TroopEntity {
        
        let troop: TroopEntity
        
        // Define qual factory usar com base no tipo
        switch type {
        case .melee:
            // O closure allTroops pode ser simplificado se não for mais necessário
            troop = TroopFactory.makeMelee(team: team) { [] }
        case .ranged:
            troop = TroopFactory.makeRanged(team: team) { [] }
        }
        
        // Define a posição inicial da tropa
        troop.component(ofType: GKSKNodeComponent.self)?.node.position = position
        
        // Futuramente, você pode adicionar a lógica de IA inicial aqui.
        // Por exemplo, fazer a tropa mirar no Nexus inimigo.
        
        return troop
    }
}
