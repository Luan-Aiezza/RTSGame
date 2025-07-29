import SpriteKit

final class ECSManager {
    typealias EntityID = UUID

    // Armazenamento dos componentes
    var movementComponents: [EntityID: MovementComponent] = [:]
    var positionComponents: [EntityID: PositionComponent] = [:]
    var nodeReferences: [EntityID: SKNode] = [:]
    var controllerComponents: [EntityID: ControllerComponent] = [:]

    func createEntity() -> EntityID {
        return UUID()
    }
}
