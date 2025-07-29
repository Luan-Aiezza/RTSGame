import SpriteKit

final class ECSManager {
    typealias EntityID = UUID

    // Armazenamento dos componentes
    var movementComponents: [EntityID: MovementComponent] = [:]
    var positionComponents: [EntityID: PositionComponent] = [:]
    var nodeReferences: [EntityID: SKNode] = [:]

    func createEntity() -> EntityID {
        return UUID()
    }
}
