//
//  TeamViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 14/09/25.
//

import UIKit

final class TeamViewController: UIViewController {

    private let teamView: TeamView

    init(teamView: TeamView) {
        self.teamView = teamView
        super.init(nibName: nil, bundle: nil)
        self.teamView.onFinished = { [weak self] in
            self?.goToHome()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = teamView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Inicia a animação ao aparecer
        teamView.startAnimation(totalDuration: 5.0)
    }

    private func goToHome() {
        // Cria HomeViewController e substitui o root com transição suave
        let home = HomeView(frame: .zero)
        let homeVC = HomeViewController(homeView: home)

        guard let window = view.window ?? (UIApplication.shared.delegate as? AppDelegate)?.window else {
            // Fallback: apresenta modal se não houver window acessível
            present(homeVC, animated: true, completion: nil)
            return
        }

        // Transição cross dissolve
        UIView.transition(with: window, duration: 0.5, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
            window.rootViewController = homeVC
        }
    }
}

