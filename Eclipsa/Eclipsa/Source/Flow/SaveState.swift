//
//  SaveState.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 02/10/25.
//

import Foundation

struct GameSaveState: Codable {
    var currentPhase: Int
    
}

extension UserDefaults {
    private static let saveKey = "GameSaveState"
    
    func saveGameState(_ state: GameSaveState) {
        if let data = try? JSONEncoder().encode(state) {
            set(data, forKey: UserDefaults.saveKey)
        }
    }
    
    func loadGameState() -> GameSaveState? {
        guard let data = data(forKey: UserDefaults.saveKey) else { return nil }
        return try? JSONDecoder().decode(GameSaveState.self, from: data)
    }
    
    func clearGameState() {
        removeObject(forKey: UserDefaults.saveKey)
    }
}
