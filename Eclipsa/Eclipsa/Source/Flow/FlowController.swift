//
//  FlowController.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//
import UIKit
import SpriteKit

class FlowController {
    
    var navigation: UINavigationController?
    var window: UIWindow
    var factory: ViewControllerFactory
    
    init(window: UIWindow) {
        self.window = window
        self.factory = ViewControllerFactory()
    }
    
    func start() -> UINavigationController? {
        let teamLogoView = factory.makeTeamLogoViewController(flowDelegate: self)
        self.navigation = UINavigationController(rootViewController: teamLogoView)
        return navigation
    }
    
}

// MARK: TeamLogo to Home
extension FlowController: TeamLogoFlowDelegate {
    func goHome() {
        let homeViewController = factory.makeHomeViewController(flowDelegate: self)
        navigation?.navigationBar.isHidden = true
        
        let transition = CATransition()
            transition.duration = 0.3
            transition.type = .fade
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        navigation?.dismiss(animated: false)
        navigation?.view.layer.add(transition, forKey: kCATransition)
        navigation?.pushViewController(homeViewController, animated: false)
    }
}

// MARK: Home to Game
extension FlowController: HomeFlowDelegate {
    func goToGame() {
        let gameViewController = factory.makeGameViewController(flowDelegate: self)

        // Ensure navigation bar is hidden for the game
        navigation?.navigationBar.isHidden = true

        // Perform a cross-dissolve on the navigation controller's view and swap the stack
        if let navView = navigation?.view {
            UIView.transition(with: navView, duration: 0.5, options: [.transitionCrossDissolve, .allowAnimatedContent, .curveEaseInOut]) { [weak self] in
                self?.navigation?.setViewControllers([gameViewController], animated: false)
            }
        } else {
            // Fallback: set without animation if nav/view not available
            navigation?.setViewControllers([gameViewController], animated: false)
        }
    }
}
