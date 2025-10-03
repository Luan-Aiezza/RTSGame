//
//  TutorialViewController.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/09/25.
//
import Foundation
import SpriteKit

class TutorialViewController: GameViewController {
    
    override func viewDidLayoutSubviews() {
        let scene = sceneManager.tutorial()//Mudar para tutorial
        scene?.pauseButtonDelegate = self
        DispatchQueue.main.async {
            self.skView.presentScene(scene)
        }
    }
}
