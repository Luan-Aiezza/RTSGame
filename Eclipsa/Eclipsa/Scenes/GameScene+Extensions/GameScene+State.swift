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
    
    // MARK: - Visual FX
    func playFollowEffectAtPlayer(timePerFrame: TimeInterval = 0.04) {
        guard let playerNode = controlledEntity?.component(ofType: AnimationComponent.self)?.node else { return }
        
        let textures: [SKTexture] = (1...13).map { SKTexture(imageNamed: "Follow_Effect_\($0)") }
        guard !textures.isEmpty else { return }
        
        let effectNode = SKSpriteNode(texture: textures.first)
        effectNode.name = "FollowEffect" // nome para o depth sort reconhecer
        effectNode.alpha = 0.6
        effectNode.position = CGPoint(
            x: playerNode.position.x,
            y: playerNode.position.y - 12
        )
        // zPosition inicial será ajustado pelo depth sort; aqui não importa mais
        effectNode.isUserInteractionEnabled = false
        effectNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        addChild(effectNode)
        
        let animate = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: false, restore: false)
        let sequence = SKAction.sequence([
            animate,
            .removeFromParent()
        ])
        effectNode.run(sequence)
    }
}
