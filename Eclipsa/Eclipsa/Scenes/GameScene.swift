import Foundation
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene {
    private var controlledEntity: UnitEntity!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        setupVirtualController()
        
        controlledEntity = UnitEntity()
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
       
        if let camera = self.camera {
            controlledEntity.setupCameraComponent(cameraNode: camera)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if let moveComponent = controlledEntity.moveComponent {
            let isMoving = moveComponent.direction != .zero
            if let stateMachineComponent = controlledEntity.component(ofType: StateMachineComponent.self) {
                if isMoving {
                    stateMachineComponent.stateMachine.enter(WalkingState.self)
                } else {
                    stateMachineComponent.stateMachine.enter(IdleState.self)
                }
            }
        }
    }
}
