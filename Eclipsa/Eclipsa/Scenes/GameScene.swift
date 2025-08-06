import Foundation
import SpriteKit
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    private var controlledEntity: UnitEntity!
    private var cameraEntity: CameraEntity!
    private var troopNode: SKSpriteNode?
    private var wallNode: SKSpriteNode?
    
    private var physicsSystem = PhysicsSystem()
    private var collisionSystem: CollisionSystem!
    private var troopControlSystem: TroopControlSystem!  // Adicionado
    
    // Lista de tropas para controle coletivo
    private var troops: [TroopEntity] = []
    
    private var troopControlButtons: TroopControlButtons!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        setupVirtualController()
        
        controlledEntity = UnitEntity(team: .sun)
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
       
        if let camera = self.camera {
            cameraEntity = CameraEntity()
            cameraEntity.setupComponents(cameraNode: camera)
            cameraEntity.followPlayer(player: controlledEntity)
            SKEntityManager.shared.add(cameraEntity)
            
            troopControlButtons = TroopControlButtons(size: self.size)
            troopControlButtons.onFollow = { [weak self] in self?.troopControlSystem.commandTroopsToFollow() }
            troopControlButtons.onRelease = { [weak self] in self?.troopControlSystem.commandTroopsToStop() }
            camera.addChild(troopControlButtons)
        }
        
        physicsSystem.setupHeroPhysics(for: controlledEntity)
        
        // Criar e adicionar 3 tropas próximas ao herói
        let basePosition = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero
        let startingPositions = [
            CGPoint(x: basePosition.x + 50, y: basePosition.y),
            CGPoint(x: basePosition.x + 90, y: basePosition.y + 90),
            CGPoint(x: basePosition.x + 120, y: basePosition.y - 90)
        ]
        
        for position in startingPositions {
            let troop = TroopEntity(team: .sun)
            troop.component(ofType: GKSKNodeComponent.self)?.node.position = position
            physicsSystem.setupTroopPhysics(for: troop)
            SKEntityManager.shared.add(troop)
            troops.append(troop)
            if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
                addChild(node)
            }
        }
        
        // Inicializar troopControlSystem após adicionar tropas
        troopControlSystem = TroopControlSystem(scene: self, troops: troops, controlledEntity: controlledEntity)
        
        let wall = physicsSystem.makeTestBlock(position: CGPoint(x: -200, y: 0))
        addChild(wall)
        wallNode = wall
        
        // Ajustar collisionSystem para trabalhar com tropas ao invés do bloco de teste
        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: nil)
        
        // Configura delegate de contato
        self.physicsWorld.contactDelegate = self
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
    
    // Removidos os métodos commandTroopsToFollow e commandTroopsToStop conforme instruções
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let camera = self.camera {
            let locInCamera = convert(location, to: camera)
            troopControlButtons.handleTouch(locInCamera)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera,
                let location = touches.first?.location(in: camera),
              location.x <= 0 else { return }
        virtualController?.touchesEnded(touches, with: event)
//        virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera,
                let location = touches.first?.location(in: camera),
              location.x <= 0 else { return }
        virtualController?.touchesCancelled(touches, with: event)
//        virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
}

extension GameScene {
    func didBegin(_ contact: SKPhysicsContact) {
        collisionSystem.handleDidBegin(contact)
    }

    func didEnd(_ contact: SKPhysicsContact) {
        collisionSystem.handleDidEnd(contact)
    }
}
