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

extension TestGameScene: ControlableDelegate {
    func handleMovement(direction: CGPoint) {
        guard let entity = controlledEntity,
                      let renderComponent = entity.component(ofType: RenderComponent.self) else {
                    return
                }
            
            // Velocidade de movimento
            let moveSpeed: CGFloat = 200.0 // pixels por segundo
            
            // Usando o deltaTime real da SKGameScene
            let deltaTime = CGFloat(1.0/60.0) // ou você pode passar o dt do update se quiser
            let movement = CGPoint(
                x: direction.x * moveSpeed * deltaTime,
                y: direction.y * moveSpeed * deltaTime
            )
            
            // Aplicando movimento ao node
            if let spriteNode = renderComponent.spriteNode {
                spriteNode.position = CGPoint(
                    x: spriteNode.position.x + movement.x,
                    y: spriteNode.position.y + movement.y
                )
            } else if let shapeNode = renderComponent.shapeNode {
                shapeNode.position = CGPoint(
                    x: shapeNode.position.x + movement.x,
                    y: shapeNode.position.y + movement.y
                )
                print("shapeNode")
            }
        }
    
    func handleButtonAPressed() {
        print("A Pressed")
    }
    
    
}
