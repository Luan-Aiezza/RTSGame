import Foundation
import SpriteKit
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    private var controlledEntity: UnitEntity!
    private var cameraEntity: CameraEntity!
    private var troopNode: SKSpriteNode?
    private var enemyNode: SKSpriteNode?
    private var commandController: VirtualController?
    private var commandInput: InputHandler?
    
    private var physicsSystem = PhysicsSystem()
    private var collisionSystem: CollisionSystem!
    private var troopControlSystem: TroopControlSystem!  // Adicionado
    
    // Lista de tropas para controle coletivo
    private var troops: [TroopEntity] = []

    private var followButton: SKSpriteNode!
    private var releaseButton: SKSpriteNode!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        setupVirtualController()
        
        controlledEntity = UnitEntity(team: .sun)
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
       
        //MARK: SetupCamera
        if let camera = self.camera {
            cameraEntity = CameraEntity()
            cameraEntity.setupComponents(cameraNode: camera)
            cameraEntity.followPlayer(player: controlledEntity)
            SKEntityManager.shared.add(cameraEntity)
        }
        
        physicsSystem.setupHeroPhysics(for: controlledEntity)
        
        // Criar e adicionar 3 tropas próximas ao herói
        let basePosition = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero
        let startingPositions = [
            CGPoint(x: basePosition.x + 50, y: basePosition.y),
            CGPoint(x: basePosition.x + 70, y: basePosition.y + 30),
            CGPoint(x: basePosition.x + 90, y: basePosition.y - 30)
        ]
        
        for position in startingPositions {
            let troop = TroopEntity(team: .sun)
            troop.component(ofType: GKSKNodeComponent.self)?.node.position = position
            SKEntityManager.shared.add(troop)
            troops.append(troop)
            if let node = troop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
                addChild(node)
            }
        }
        
        // Inicializar troopControlSystem após adicionar tropas
        troopControlSystem = TroopControlSystem(scene: self, troops: troops, controlledEntity: controlledEntity)
        
        let troop = physicsSystem.makeTroop(position: CGPoint(x: -200, y: 0))
        addChild(troop)
        troopNode = troop
        
        let enemyEntity = UnitEntity(team: .moon)
        SKEntityManager.shared.add(enemyEntity)
        let enemy = physicsSystem.makeTroop(position: CGPoint(x: -200, y: 0))
        addChild(enemy)
        enemyNode = enemy
        
        // Ajustar collisionSystem para trabalhar com tropas ao invés do bloco de teste
        collisionSystem = CollisionSystem(controlledEntity: controlledEntity, testBlockNode: nil)
        
        // Configura delegate de contato
        self.physicsWorld.contactDelegate = self

        let buttonSize = CGSize(width: 64, height: 64)
        followButton = SKSpriteNode(color: .green, size: buttonSize)
        followButton.alpha = 0.7
        followButton.position = CGPoint(x: self.size.width/2 - 80, y: -self.size.height/2 + 160)
        followButton.zPosition = 1000
        followButton.name = "followButton"
        let followLabel = SKLabelNode(text: "Follow")
        followLabel.fontName = "Avenir-Black"
        followLabel.fontSize = 22
        followLabel.fontColor = .white
        followLabel.verticalAlignmentMode = .center
        followButton.addChild(followLabel)
        addChild(followButton)

        releaseButton = SKSpriteNode(color: .red, size: buttonSize)
        releaseButton.alpha = 0.7
        releaseButton.position = CGPoint(x: self.size.width/2 - 80, y: -self.size.height/2 + 80)
        releaseButton.zPosition = 1000
        releaseButton.name = "releaseButton"
        let releaseLabel = SKLabelNode(text: "Release")
        releaseLabel.fontName = "Avenir-Black"
        releaseLabel.fontSize = 22
        releaseLabel.fontColor = .white
        releaseLabel.verticalAlignmentMode = .center
        releaseButton.addChild(releaseLabel)
        addChild(releaseButton)
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
        let nodes = nodes(at: location)
        for node in nodes {
            if node.name == "followButton" {
                troopControlSystem.commandTroopsToFollow()
            } else if node.name == "releaseButton" {
                troopControlSystem.commandTroopsToStop()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        
        if location.x < 0 {
            virtualController?.touchMoved(touches, with: event)
        } else {
            virtualController?.touchesCancelled(touches, with: event)
            virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualController?.touchesEnded(touches, with: event)
        virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualController?.touchesCancelled(touches, with: event)
        virtualController?.setAnalogVisible(value: false, withDuration: 0.6)
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
