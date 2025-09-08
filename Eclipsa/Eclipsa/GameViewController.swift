//
//  GameViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 28/07/25.
//

import UIKit
import SpriteKit
import GameplayKit
import GameController

class GameViewController: UIViewController {
    
    private var skView: SKView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHomeScreen()
    }
    
    // MARK: - Home Screen
    private func setupHomeScreen() {
        view.backgroundColor = .black
        
        let home = HomeScreen()
        home.translatesAutoresizingMaskIntoConstraints = false
        home.onPlayTapped = { [weak self] in
            self?.didTapPlay()
        }
        view.addSubview(home)
        
        NSLayoutConstraint.activate([
            home.topAnchor.constraint(equalTo: view.topAnchor),
            home.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            home.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            home.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Start Game
    @objc private func didTapPlay() {
        startGame(sceneNamed: "GameScene_1")
    }
    
    private func startGame(sceneNamed name: String) {
        // Remove qualquer SKView ou subviews anteriores (como a home)
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // Cria o SKView e adiciona à hierarquia
        let skView = SKView(frame: view.bounds)
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.skView = skView
        
        // Configurações de debug (opcional)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.isMultipleTouchEnabled = true
        // skView.showsPhysics = true
        
        // Carrega a cena via GKScene para manter o pipeline existente
        if let gkScene = GKScene(fileNamed: name),
           let sceneNode = gkScene.rootNode as? GameScene {
            sceneNode.scaleMode = .aspectFill
            skView.presentScene(sceneNode)
        } else if let sceneNode = GameScene(fileNamed: name) {
            // Fallback caso o GKScene não esteja configurado
            sceneNode.scaleMode = .aspectFill
            skView.presentScene(sceneNode)
        } else {
            assertionFailure("Não foi possível carregar a cena \(name)")
            // Em caso de falha, volta para a Home
            view.subviews.forEach { $0.removeFromSuperview() }
            setupHomeScreen()
        }
    }

    // MARK: - Public navigation back to Home
    public func returnToHome() {
        // Remove a cena atual e volta a mostrar a HomeScreen
        skView?.presentScene(nil)
        skView?.removeFromSuperview()
        skView = nil
        setupHomeScreen()
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
