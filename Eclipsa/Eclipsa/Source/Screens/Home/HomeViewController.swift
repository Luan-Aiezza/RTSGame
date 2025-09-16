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
    }
    override func loadView() {
        view = homeView
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
