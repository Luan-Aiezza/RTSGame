//
//  HomeViewController.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/09/25.
//

import UIKit

class HomeViewController: UIViewController {
    private let homeView: HomeView
    public weak var flowDelegate: HomeFlowDelegate?
    
    init(homeView: HomeView, flowDelegate: HomeFlowDelegate) {
        self.homeView = homeView
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    override func loadView() {
        homeView.delegate = self
        view = homeView
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AudioManager.shared.fadeInBackgroundMusic(named: "OST_HomeView", duration: 3)

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Faz fade out ao sair da Home
        AudioManager.shared.fadeOutBackgroundMusic(stopAfter: false)
    }
}

// MARK: Bindando ViewController com View
extension HomeViewController: HomeViewDelegate {
    func didTapConfigurationButton() {
        AudioManager.shared.playSound(named: "Effect_Select_1")
        flowDelegate?.goToConfiguration()
    }
    
    func didTapPlayButton() {
        AudioManager.shared.playSound(named: "Effect_Confirm_1")
        flowDelegate?.goToGame()
    }
    
    func didTapMultiplayerButton() {
        AudioManager.shared.playSound(named: "Effect_Confirm_1")
        flowDelegate?.goToMultiplayer()
    }
}

protocol HomeFlowDelegate: AnyObject {
    func goToGame()
    func goToMultiplayer()
    func goToConfiguration()
}

protocol HomeViewDelegate: AnyObject {
    func didTapPlayButton()
    func didTapConfigurationButton()
    func didTapMultiplayerButton()
}
