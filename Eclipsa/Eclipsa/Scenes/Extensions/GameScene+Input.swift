// GameScene+Input.swift
import SpriteKit
import BehindGameKit
import GameplayKit

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        // Converter o ponto de toque da coordenada da câmera para a cena global
        let locationInScene = camera.convert(location, to: self)
        
        if location.x <= 0 {
            gameController?.setAnalogVisible(value: true)
            gameController?.changePosition(location)
            gameController?.touchBegan(touches, with: event)
        } else if location.x > 0 {
            commandController?.setAnalogVisible(value: true)
            aimingSystem?.startAiming()
            commandController?.changePosition(location)
            commandController?.touchBegan(touches, with: event)
            commandButton.toggleCommand(value: false)
        }
        troopControlButtons.handleTouch(location)
        
        // Only move troops if not tapping Follow button
        let buttonNodes = troopControlButtons.nodes(at: location)
        let tappedFollow = buttonNodes.contains { $0.name == "followButton" }
        if !tappedFollow {
            for troop in troops {
                if let behavior = troop.component(ofType: TroopBehaviorComponent.self),
                   let target = (behavior as? TroopBehaviorComponent)?.target as? UnitEntity, target === controlledEntity {
                    troop.moveTo(point: locationInScene)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        if location.x <= 0 {
            gameController?.touchMoved(touches, with: event)
        } else {
            commandController?.touchMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera
                ,let location = touches.first?.location(in: camera) else { return }
        if location.x <= 0 {
            gameController?.touchesEnded(touches, with: event)
            gameController?.setAnalogVisible(value: false, withDuration: 0.6)
        } else {
            commandButton.handleTouch(location)
            aimingSystem?.finishAiming { [weak self] result in
                self?.commandButton.toggleCommand(value: true)
            }
            commandController?.touchesEnded(touches, with: event)
            commandController?.setAnalogVisible(value: false, withDuration: 0.6)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameController?.touchesCancelled(touches, with: event)
        gameController?.setAnalogVisible(value: false, withDuration: 0.6)
       commandController?.touchesEnded(touches, with: event)
       commandController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
}
