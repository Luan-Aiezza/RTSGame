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
        // Inicia a trilha com fade in
        AudioManager.shared.fadeOutBackgroundMusic()
        
        DispatchQueue.main.asyncAfter(deadline: .now()){
            AudioManager.shared.fadeInBackgroundMusic(named: "OST_HomeView")
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Faz fade out ao sair da Home
        AudioManager.shared.fadeOutBackgroundMusic(duration: 1.0, stopAfter: true)
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
}

protocol HomeFlowDelegate: AnyObject {
    func goToGame()
    
    func goToConfiguration()
}

protocol HomeViewDelegate: AnyObject {
    func didTapPlayButton()
    func didTapConfigurationButton()
}
