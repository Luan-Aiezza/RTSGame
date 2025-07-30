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

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.setupVirtualController()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene") {
            
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! GameScene? {
                
                
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                
                // Present the scene
                let skView = SKView(frame: view.bounds)
                skView.translatesAutoresizingMaskIntoConstraints = false
                
                view.addSubview(skView)
                
                skView.presentScene(sceneNode)
                skView.ignoresSiblingOrder = true
                skView.showsFPS = true
                skView.showsNodeCount = true
                skView.showsDrawCount = true
                
                NSLayoutConstraint.activate([
                    skView.topAnchor.constraint(equalTo: view.topAnchor),
                    skView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                    skView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        }
    }

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
