import SpriteKit

func createPlayerEntity(in scene: SKScene, ecs: ECSManager) -> UUID {
    let entityID = ecs.createEntity()

    // Componentes
    ecs.positionComponents[entityID] = PositionComponent(position: CGPoint(x: 100, y: 100))
    ecs.movementComponents[entityID] = MovementComponent(
        velocity: CGVector(dx: 50, dy: 0), // velocidade constante para a direita
        maxSpeed: 100
    )
    ecs.controllerComponents[entityID] = ControllerComponent(destination: nil)

    // Representação visual (quadrado azul)
    let square = SKShapeNode(rectOf: CGSize(width: 32, height: 32))
    square.fillColor = .blue
    square.position = CGPoint(x: 0, y: 0)
    scene.addChild(square)

    // Referência visual vinculada ao ECS
    ecs.nodeReferences[entityID] = square

    return entityID
}
