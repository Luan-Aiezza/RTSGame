//
//  TestGameScene.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 30/07/25.
//

import Foundation
import BehindGameKit
import GameplayKit
internal import Combine

class TestGameScene: SKGameScene {
    private var controlledEntity: GKEntity!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        setupVirtualController()
        
        controlledEntity = UnitEntity()
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
    }
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesMoved(touches, with: event)
//        if let control = entity?.component(ofType: ControlableComponent.self){
//            control.setupController(inputHandler: inputHandler, virtualController: virtualController)
//        }
//        
//        inputHandler.$directionAxis.sink(receiveValue: { [weak self] direction in
//            print(direction)
//        })
//    }
}
