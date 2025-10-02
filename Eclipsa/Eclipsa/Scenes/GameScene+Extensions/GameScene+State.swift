// GameScene+PlayerState.swift
import GameplayKit
import BehindGameKit

extension GameScene {
    func updatePlayerState() {
        // Se não há player (ex.: durante respawn), não faz nada
        guard let player = controlledEntity else { return }
        // Se o player não tem componente de movimento, também não há o que fazer
        guard let moveComponent = player.moveComponent else { return }
        
        let isMoving = moveComponent.direction != .zero
        
        if let stateMachineComponent = player.component(ofType: StateMachineComponent.self) {
            if isMoving {
                stateMachineComponent.stateMachine.enter(WalkingState.self)
            } else {
                stateMachineComponent.stateMachine.enter(IdleState.self)
            }
        }
    }
}
