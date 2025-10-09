//
//  MultiplayerGameScene.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import SpriteKit
import GameKit

final class MultiplayerGameScene: SKScene {
    private var match: GKMatch

    init(size: CGSize, match: GKMatch) {
        self.match = match
        super.init(size: size)
        backgroundColor = .black
        match.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        print("🕹️ MultiplayerGameScene started")
        // Aqui você pode inicializar seu RTS Multiplayer
    }
}

extension MultiplayerGameScene: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        print("📨 Dados recebidos de \(player.displayName)")
        // decodifique eventos de jogo
    }
}
