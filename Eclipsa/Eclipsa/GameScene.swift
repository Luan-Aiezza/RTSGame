//
//  GameScene.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 28/07/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func sceneDidLoad() {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {

    }
}
