import SpriteKit

struct ControllerSystem {
    static func update(deltaTime: TimeInterval, ecs: ECSManager) {
        for (entityID, controller) in ecs.controllerComponents {
            guard var movement = ecs.movementComponents[entityID],
                  var position = ecs.positionComponents[entityID] else { continue }
            guard let destination = controller.destination else {
                // Se não há destino, zera a velocidade
                movement.velocity = .zero
                ecs.movementComponents[entityID] = movement
                continue
            }

            let toTarget = CGVector(dx: destination.x - position.position.x,
                                   dy: destination.y - position.position.y)
            let distance = sqrt(toTarget.dx * toTarget.dx + toTarget.dy * toTarget.dy)
            let threshold: CGFloat = 4.0 // Distância para parar

            if distance < threshold {
                // Chegou ao destino, para o movimento
                movement.velocity = .zero
            } else {
                // Move em direção ao destino com velocidade constante
                let direction = CGVector(dx: toTarget.dx / distance, dy: toTarget.dy / distance)
                movement.velocity = CGVector(dx: direction.dx * movement.maxSpeed, dy: direction.dy * movement.maxSpeed)
            }
            ecs.movementComponents[entityID] = movement
        }
    }
}
