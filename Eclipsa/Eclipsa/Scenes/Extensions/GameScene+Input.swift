// GameScene+Input.swift
import SpriteKit
import BehindGameKit

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        touchHandler?.touchesBegan(touches, with: event)

        if location.x <= 0 {
            commandController?.setAnalogVisible(value: true)
            commandController?.changePosition(location)
            commandController?.touchBegan(touches, with: event)
        }
        troopControlButtons.handleTouch(location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        touchHandler?.touchesMoved(touches, with: event)

        if location.x < 0 {
            commandController?.touchMoved(touches, with: event)
        } else {
            commandController?.touchesCancelled(touches, with: event)
            commandController?.setAnalogVisible(value: false, withDuration: 0.6)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        commandController?.touchesEnded(touches, with: event)
        commandController?.setAnalogVisible(value: false, withDuration: 0.6)
        touchHandler?.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        commandController?.touchesCancelled(touches, with: event)
        commandController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
}
