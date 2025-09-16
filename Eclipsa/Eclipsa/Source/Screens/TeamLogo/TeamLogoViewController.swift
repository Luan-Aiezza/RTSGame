//
//  TeamViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 14/09/25.
//

import UIKit

final class TeamLogoViewController: UIViewController {

    private let teamLogoView: TeamLogoView
    public weak var flowDelegate: TeamLogoFlowDelegate?

    init(teamView: TeamLogoView, flowDelegate: TeamLogoFlowDelegate) {
        self.teamLogoView = teamView
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
        self.teamLogoView.onFinished = { [weak self] in
            self?.goToHome()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = teamLogoView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Inicia a animação ao aparecer
        teamLogoView.startAnimation(totalDuration: 5.0)
    }

    private func goToHome() {
        // Cria HomeViewController e substitui o root com transição suave

//        guard let window = view.window ?? (UIApplication.shared.delegate as? AppDelegate)?.window else {
//            // Fallback: apresenta modal se não houver window acessível
//            present(homeVC, animated: true, completion: nil)
//            return
//        }

        // Transição cross dissolve
        UIView.transition(with: self.teamLogoView, duration: 0.5, options: [.transitionCrossDissolve, .allowAnimatedContent]) { [weak self] in
//            window.rootViewController = homeVC
            self?.flowDelegate?.goHome()
        }
        
    }
}

protocol TeamLogoFlowDelegate: AnyObject {
    func goHome()
}
