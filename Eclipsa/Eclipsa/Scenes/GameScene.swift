import SpriteKit

class GameScene: SKScene {
    let ecs = ECSManager()
    var playerID: UUID? = nil
    var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .black
        playerID = createPlayerEntity(in: self, ecs: ecs)
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        ControllerSystem.update(deltaTime: deltaTime, ecs: ecs)
        MovementSystem.update(deltaTime: deltaTime, ecs: ecs)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let playerID else { return }
        let location = touch.location(in: self)
        ecs.controllerComponents[playerID]?.destination = location
    }
}
