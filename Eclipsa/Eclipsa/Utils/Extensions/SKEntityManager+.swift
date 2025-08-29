//
//  SKEntityManager+.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 29/08/25.
//

import BehindGameKit
import GameplayKit

extension SKEntityManager {
    
    public func getMyTeamTroops(team: Team) -> Set<TroopEntity> {
        let entities = getAllEntities()
            .compactMap({ $0 as? TroopEntity
            })
            .filter { $0.component(ofType: TeamComponent.self)?.team == team }
        return Set(entities)
    }
    
    public func getAllGameTroops() -> Set<TroopEntity> {
        let entities = getAllEntities()
            .compactMap({ $0 as? TroopEntity
            })
        return Set(entities)
    }
    
    
}
