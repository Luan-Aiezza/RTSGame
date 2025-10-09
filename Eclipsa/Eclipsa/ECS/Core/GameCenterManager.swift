//
//  GameCenterManager.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import GameKit
import UIKit

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

    /// Autentica o jogador no Game Center, apresentando o login se necessário.
    /// - Parameter presentingViewController: View controller que irá apresentar a UI do Game Center.
    func authenticateIfNeeded(presentingViewController: UIViewController?) {
        let localPlayer = GKLocalPlayer.local

        // Handler de autenticação pode ser chamado múltiplas vezes ao longo do ciclo de vida.
        localPlayer.authenticateHandler = { vc, error in
            if let error = error {
                print("[GameCenter] Erro de autenticação: \(error.localizedDescription)")
            }

            if let vc = vc, let presenter = presentingViewController {
                // Apresenta a UI de login do Game Center
                presenter.present(vc, animated: true)
                return
            }

            if localPlayer.isAuthenticated {
                print("[GameCenter] Jogador autenticado: \(localPlayer.displayName)")
            } else {
                print("[GameCenter] Jogador não autenticado e nenhuma UI foi apresentada.")
            }
        }
    }
}
