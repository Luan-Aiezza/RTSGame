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
}

// MARK: Bindando ViewController com View
extension HomeViewController: HomeViewDelegate {
    func didTapPlayButton() {
        flowDelegate?.goToGame()
    }
}

protocol HomeFlowDelegate: AnyObject {
    func goToGame()
}

protocol HomeViewDelegate: AnyObject {
    func didTapPlayButton()
}
