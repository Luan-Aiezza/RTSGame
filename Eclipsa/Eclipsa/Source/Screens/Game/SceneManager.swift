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
        return scene
    }
    
    private func makeScene(with name: String) -> GameScene? {
        guard let gkScene = GKScene(fileNamed: name),
              let sceneNode = gkScene.rootNode as? GameScene else { return nil}
            sceneNode.scaleMode = .aspectFill
            return sceneNode
    }
}
