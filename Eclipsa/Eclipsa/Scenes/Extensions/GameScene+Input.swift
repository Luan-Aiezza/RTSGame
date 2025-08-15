// GameScene+Input.swift
import SpriteKit
import BehindGameKit

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
//        touchHandler?.touchesBegan(touches, with: event)
        
        if location.x <= 0 {
            gameController?.setAnalogVisible(value: true)
            gameController?.changePosition(location)
            gameController?.touchBegan(touches, with: event)
        } else if location.x > 0 {
            aimingSystem?.startAiming()
            commandController?.setAnalogVisible(value: true)
            commandController?.changePosition(location)
            commandController?.touchBegan(touches, with: event)
        }
        troopControlButtons.handleTouch(location)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let _ = touches.first?.location(in: camera) else { return }
//        touchHandler?.touchesMoved(touches, with: event)
        gameController?.touchMoved(touches, with: event)
        commandController?.touchMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameController?.touchesEnded(touches, with: event)
        gameController?.setAnalogVisible(value: false, withDuration: 0.6)
        commandController?.touchesEnded(touches, with: event)
        commandController?.setAnalogVisible(value: false, withDuration: 0.6)
//        touchHandler?.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameController?.touchesCancelled(touches, with: event)
        gameController?.setAnalogVisible(value: false, withDuration: 0.6)
       commandController?.touchesEnded(touches, with: event)
       commandController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
}
