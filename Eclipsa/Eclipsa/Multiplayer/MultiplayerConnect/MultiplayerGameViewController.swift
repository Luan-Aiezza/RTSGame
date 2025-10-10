//
//  MultiplayerViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import UIKit
import SpriteKit
import GameKit

final class MultiplayerGameViewController: UIViewController {
    private let match: GKMatch
    weak var flowDelegate: FlowController?
    
    init(match: GKMatch, flowDelegate: FlowController) {
        self.match = match
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = SKView(frame: view.bounds)
        view.addSubview(skView)
        
        if let scene = SKScene(fileNamed: "MultiplayerGameScene") as? MultiplayerGameScene {
            scene.configure(with: match)
            scene.scaleMode = .resizeFill
            skView.presentScene(scene)
        }
    }
}
