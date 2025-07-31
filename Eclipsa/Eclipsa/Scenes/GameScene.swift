import Foundation
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene {
    private var controlledEntity: GKEntity!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        setupVirtualController()
        
        controlledEntity = UnitEntity()
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if let controlledEntity = controlledEntity as? UnitEntity,
           let moveComponent = controlledEntity.moveComponent {
            let isMoving = moveComponent.direction != .zero
            controlledEntity.component(ofType: StateComponent.self)?.updateState(moving: isMoving)
        }
    }
}
