//
//  TroopGeneratorComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/08/25.
//
import GameplayKit
import BehindGameKit

class TroopGeneratorComponent: GKComponent {
    weak var scene: SKScene?
    var spawnPosition: CGPoint = .zero
    var spawnOffset: CGPoint {
        let angle = Double.random(in: 0..<2*Double.pi)
        let radius = Double.random(in: 20...50)
        return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
    }
    
    var generatedTroops = Set<TroopEntity>()
    var limitTroops: Int = 5
    
    func generateTroop() -> TroopEntity?{
        if limitTroops > generatedTroops.count {
            let position = spawnPosition + spawnOffset
            let troop = TroopEntity.createTroop(at: position, team: Team.sun)
            generatedTroops.insert(troop)
            return troop
        }
        return nil
    }
}
