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
    
    
    
    func makeConfigurationViewController(flowDelegate: ConfigFlowDelegate) -> ConfigViewController {
        let configViewController = ConfigViewController(flowDelegate: flowDelegate)
        configViewController.modalPresentationStyle = .fullScreen
        configViewController.modalTransitionStyle = .crossDissolve
        
        return configViewController
        
    }
    
    func makeCreditsViewController() -> CreditsViewController {
        let creditsViewController = CreditsViewController()
        creditsViewController.onFinished = {
            DispatchQueue.main.async{
                creditsViewController.dismiss(animated: true)
            }
        }
        return creditsViewController
    }
    
    func makeTutorialViewController(flowDelegate: FlowController) -> TutorialViewController {
        let tutorialViewController = TutorialViewController(flowDelegate: flowDelegate)
        tutorialViewController.modalPresentationStyle = .fullScreen
        tutorialViewController.modalTransitionStyle = .crossDissolve
        return tutorialViewController
    }
    
    func makeFirstUserViewController(flowDelegate: FirstUserFlowDelegate) -> FirstUserViewController {
        return FirstUserViewController(flowDelegate: flowDelegate)
    }
    
    func makeMultiplayerMatchViewController(flowDelegate: MultiplayerFlowDelegate) -> MultiplayerMatchViewController {
        return MultiplayerMatchViewController(flowDelegate: flowDelegate)
    }
}
