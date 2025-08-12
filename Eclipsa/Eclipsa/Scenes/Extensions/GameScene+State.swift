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
    
    func updateTroopState() {
        for troop in troops {
            guard let agentComponent = troop.component(ofType: AgentComponent.self) else { continue }
            let velocity = agentComponent.agent.velocity
            let isMoving = velocity.x != 0 || velocity.y != 0
            if let stateMachineComponent = troop.component(ofType: StateMachineComponent.self) {
                if isMoving {
                    stateMachineComponent.stateMachine.enter(WalkingState.self)
                } else {
                    stateMachineComponent.stateMachine.enter(IdleState.self)
                }
            }
            // Flip direction based on velocity.x
            if let node = troop.component(ofType: GKSKNodeComponent.self)?.node as? SKSpriteNode {
                if velocity.x > 0 {
                    node.xScale = abs(node.xScale)
                } else if velocity.x < 0 {
                    node.xScale = -abs(node.xScale)
                }
            }
        }
    }
}
