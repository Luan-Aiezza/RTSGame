//
//  MultiplayerMatchViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import UIKit
import GameKit

protocol MultiplayerFlowDelegate: AnyObject {
    func didFindMultiplayerMatch(_ match: GKMatch)
    func cancelMultiplayer()
}

final class MultiplayerMatchViewController: UIViewController {
    weak var flowDelegate: MultiplayerFlowDelegate?
    private var match: GKMatch?

    init(flowDelegate: MultiplayerFlowDelegate) {
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        startMatchmaking()
    }

    private func startMatchmaking() {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        guard let vc = GKMatchmakerViewController(matchRequest: request) else { return }
        vc.matchmakerDelegate = self
        present(vc, animated: true)
    }
}

extension MultiplayerMatchViewController: GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        flowDelegate?.cancelMultiplayer()
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        print("❌ Matchmaking error: \(error.localizedDescription)")
        viewController.dismiss(animated: true)
        flowDelegate?.cancelMultiplayer()
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        print("✅ Match found with \(match.players.count) players")
        self.match = match
        match.delegate = self
        viewController.dismiss(animated: true)
        flowDelegate?.didFindMultiplayerMatch(match)
    }

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        // Aqui você pode receber dados de jogo
        print("📡 Recebido \(data.count) bytes de \(player.displayName)")
    }
}
