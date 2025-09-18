//
//  NewGameViewController.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 16/09/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    let sceneManager: SceneManager
    let flowDelegate: FlowController
    
    private var skView: SKView
    init(flowDelegate: FlowController) {
        self.sceneManager = SceneManager()
        self.skView = SKView()
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        let scene = sceneManager.intro(size: skView.bounds.size)
        scene.onFinished = { [weak self] in
            if let phaseOne = self?.sceneManager.phaseOne(){
                DispatchQueue.main.async {
                    self?.skView.presentScene(phaseOne)
                }
            }
        }
        let transition = SKTransition.fade(withDuration: 0.4)
        skView.presentScene(scene, transition: transition)
    }
    
    func setupUI() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
//        view.addSubview(button)
        skView.isMultipleTouchEnabled = true
        setupConstraints()
        setupDebugOptions()
    }
    
    func setupConstraints(){
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupDebugOptions(){
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
    }

    // MARK: - Orientation & Status Bar
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
