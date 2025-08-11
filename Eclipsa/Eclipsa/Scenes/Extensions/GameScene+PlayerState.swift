// GameScene+PlayerState.swift
import GameplayKit
import BehindGameKit

extension GameScene {
    func updatePlayerState() {
        guard let moveComponent = controlledEntity.moveComponent else { return }
        let isMoving = moveComponent.direction != .zero
        if let stateMachineComponent = controlledEntity.component(ofType: StateMachineComponent.self) {
            if isMoving {
                stateMachineComponent.stateMachine.enter(WalkingState.self)
            } else {
                stateMachineComponent.stateMachine.enter(IdleState.self)
            }
        }
    }
}
