//
//  ViewControllerFactory.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 16/09/25.
//

import UIKit

struct ViewControllerFactory {
    func makeTeamLogoViewController(flowDelegate: TeamLogoFlowDelegate) -> TeamLogoViewController{
        let view = TeamLogoView()
        let viewController = TeamLogoViewController(teamView: view, flowDelegate: flowDelegate)
        
        return viewController
    }
    
    func makeHomeViewController(flowDelegate: HomeFlowDelegate) -> HomeViewController {
        let homeView = HomeView()
        let homeViewController = HomeViewController(homeView: homeView, flowDelegate: flowDelegate)
        
        return homeViewController
    }
    
    func makeGameViewController(flowDelegate: FlowController) -> GameViewController {
        let gameViewController = GameViewController(flowDelegate: flowDelegate)
        
        return gameViewController
    }
}
