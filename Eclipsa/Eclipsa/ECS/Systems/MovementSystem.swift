import SpriteKit

struct MovementSystem {
    static func update(deltaTime: TimeInterval, ecs: ECSManager) {
        for (entityID, movement) in ecs.movementComponents {
            guard var positionComponent = ecs.positionComponents[entityID] else { continue }

            // Aplica deslocamento à posição
            let dx = movement.velocity.dx * CGFloat(deltaTime)
            let dy = movement.velocity.dy * CGFloat(deltaTime)

            positionComponent.position.x += dx
            positionComponent.position.y += dy
            ecs.positionComponents[entityID] = positionComponent

            // Atualiza o nó visual
            if let node = ecs.nodeReferences[entityID] {
                node.position = positionComponent.position
            }
        }
    }
}
