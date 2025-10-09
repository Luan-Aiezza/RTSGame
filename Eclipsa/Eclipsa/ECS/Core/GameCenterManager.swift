//
//  GameCenterManager.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import GameKit

class GameCenterManager {
    static let shared = GameCenterManager()

    private init() {}

    func reportAchievement(identifier: String, percentComplete: Double = 100.0) {
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true // Mostra a notificação “Conquista desbloqueada!”

        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Erro ao reportar conquista: \(error.localizedDescription)")
            } else {
                print("Conquista \(identifier) reportada com sucesso!")
            }
        }
    }
}
