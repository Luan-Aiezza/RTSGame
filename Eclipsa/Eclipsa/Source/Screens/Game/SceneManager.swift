//
//  SceneManager.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 16/09/25.
//

import GameplayKit

struct SceneManager {

    func phaseOne() -> GameScene? {
        let scene = makeScene(with: "GameScene_1")
        scene?.configureScene(with: Phase1())
        return scene
    }
    
    func phaseTwo() -> GameScene? {
        let scene = makeScene(with: "GameScene_2")
        scene?.configureScene(with: Phase1())
        return scene
    }
    
    func phaseThree() -> GameScene? {
        let scene = makeScene(with: "GameScene_3")
        scene?.configureScene(with: Phase1())
        return scene
    }
    
    func phaseFour() -> GameScene? {
        let scene = makeScene(with: "GameScene_4")
        scene?.configureScene(with: Phase1())
        return scene
    }
    
    func phaseFive() -> GameScene? {
        let scene = makeScene(with: "GameScene_5")
        scene?.configureScene(with: Phase1())
        return scene
    }
    
    private func makeScene(with name: String) -> GameScene? {
        guard let gkScene = GKScene(fileNamed: name),
              let sceneNode = gkScene.rootNode as? GameScene else { return nil}
            sceneNode.scaleMode = .aspectFill
            sceneNode.name = name
            return sceneNode
    }
}
