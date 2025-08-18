// AgentComponent.swift
// Eclipsa
// Novo componente para integração de GKAgent2D com entidades SpriteKit

import SpriteKit
import GameplayKit

public class AgentComponent: GKComponent {
    public let agent: GKAgent2D
    private weak var node: SKSpriteNode?
    
    public init(node: SKSpriteNode, radius: Float = 16.0, maxSpeed: Float = 120.0, maxAcceleration: Float = 180.0) {
        self.agent = GKAgent2D()
        self.node = node
        super.init()
        self.agent.radius = radius
        self.agent.maxSpeed = maxSpeed
        self.agent.maxAcceleration = maxAcceleration
        // Inicializar posição
        let position = vector_float2(Float(node.position.x), Float(node.position.y))
        self.agent.position = position
        self.agent.delegate = self
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgentComponent: GKAgentDelegate {
    public func agentWillUpdate(_ agent: GKAgent) {
        // Atualiza a posição do agente a partir do node
        guard let node = node else { return }
        let pos = node.position
        self.agent.position = vector_float2(Float(pos.x), Float(pos.y))
    }
    
    public func agentDidUpdate(_ agent: GKAgent) {
        // Atualiza a posição do node a partir do agente
        guard let node = node else { return }
        node.position = CGPoint(x: CGFloat(self.agent.position.x), y: CGFloat(self.agent.position.y))
    }
}
