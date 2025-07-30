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
}
