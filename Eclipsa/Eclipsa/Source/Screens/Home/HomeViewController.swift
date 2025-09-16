
//
//  HomeViewController.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

import UIKit

class HomeViewController: UIViewController {
    private let homeView: HomeView
    
    init(homeView: HomeView) {
        self.homeView = homeView
        super.init(nibName: nil, bundle: nil)
        // Encaminha o toque do HomeView para o controlador
        self.homeView.onPlayTapped = { [weak self] in
            self?.goToGame()
        }
    }
    override func loadView() {
        view = homeView
    }
    private func goToGame() {
        let gameVC = GameViewController()
        // Prefer push if embedded in a navigation controller
        if let nav = navigationController {
            nav.pushViewController(gameVC, animated: true)
            return
        }
        // Try to swap the window's root for a full transition
        if let window = view.window ?? (UIApplication.shared.delegate as? AppDelegate)?.window {
            UIView.transition(with: window, duration: 0.5, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
                window.rootViewController = gameVC
            }
            return
        }
        // Fallback: present modally
        present(gameVC, animated: true)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
