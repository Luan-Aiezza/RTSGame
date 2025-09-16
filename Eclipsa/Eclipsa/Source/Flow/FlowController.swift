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
    var factory = ViewControllerFactory()
    
    func start() -> UINavigationController? {
        let teamLogoView = factory.makeTeamLogoViewController(flowDelegate: self)
        self.navigation = UINavigationController(rootViewController: teamLogoView)
        return navigation
    }
    
}

extension FlowController: TeamLogoFlowDelegate {
    func goHome() {
        let homeViewController = factory.makeHomeViewController()
        navigation?.navigationBar.isHidden = true
        
        let transition = CATransition()
            transition.duration = 0.3
            transition.type = .fade
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        navigation?.view.layer.add(transition, forKey: kCATransition)
        navigation?.pushViewController(homeViewController, animated: false)
    }
}
