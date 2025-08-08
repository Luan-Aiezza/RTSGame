import Foundation
import SpriteKit
import BehindGameKit
import GameplayKit

class GameScene: SKGameScene, SKPhysicsContactDelegate {
    private var controlledEntity: UnitEntity!
    private var cameraEntity: CameraEntity!
    private var troopNode: SKSpriteNode?
    private var enemyNode: SKSpriteNode?
    var commandController: VirtualController?
    var commandInput = InputHandler()
    private var wallNode: SKSpriteNode?
    
    private var aimingSystem: AimingSystem?
    private var touchHandler: RTSTouchHandler?
    
    private var physicsSystem = PhysicsSystem()
    private var collisionSystem: CollisionSystem!
    private var troopControlSystem: TroopControlSystem!
    // Lista de tropas para controle coletivo
    private var troops: [TroopEntity] = []
    
    private var troopControlButtons: TroopControlButtons!
    
    private var customLastUpdateTime: TimeInterval?
    
    private func nearestEnemyTroop(inRangeOf troop: TroopEntity) -> TroopEntity? {
        guard let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
              let position = troop.component(ofType: GKSKNodeComponent.self)?.node.position,
              let range = troop.component(ofType: RangeComponent.self)?.radius else { return nil }
        var nearest: (troop: TroopEntity, dist2: CGFloat)? = nil
        for other in troops {
            if other === troop { continue }
            guard let otherTeam = other.component(ofType: TeamComponent.self)?.team,
                  otherTeam != troopTeam,
                  let otherPos = other.component(ofType: GKSKNodeComponent.self)?.node.position else { continue }
            let d2 = (position.x - otherPos.x) * (position.x - otherPos.x) + (position.y - otherPos.y) * (position.y - otherPos.y)
            if d2 <= range * range {
                if nearest == nil || d2 < nearest!.dist2 {
                    nearest = (other, d2)
                }
            }
        }
        return nearest?.troop
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        setupVirtualController()
        
        //MARK: Create Dummy
        commandController = .init(scene: self, analogRadius: 25)
        commandController?.setAnalogVisible(value: false)
        commandInput.observeGameController()
        
        //MARK: Create Player
        controlledEntity = UnitEntity(team: .sun)
        SKEntityManager.shared.add(controlledEntity)
        
        controlledEntity.component(ofType: ControlableComponent.self)?.setupController(inputHandler: inputHandler, virtualController: virtualController)
       
        setupRTSAiming()
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
        
        let enemyPositions = [
            CGPoint(x: basePosition.x - 50, y: basePosition.y),
            CGPoint(x: basePosition.x - 90, y: basePosition.y - 90),
            CGPoint(x: basePosition.x - 120, y: basePosition.y + 90)
        ]
        for position in enemyPositions {
            let enemyTroop = TroopEntity(team: .moon)
            enemyTroop.component(ofType: GKSKNodeComponent.self)?.node.position = position
            physicsSystem.setupTroopPhysics(for: enemyTroop)
            SKEntityManager.shared.add(enemyTroop)
            troops.append(enemyTroop)
            if let node = enemyTroop.component(ofType: GKSKNodeComponent.self)?.node, node.parent == nil {
                addChild(node)
            }
        }
        
        // Inicializar troopControlSystem antes da criação dos botões
        troopControlSystem = TroopControlSystem(scene: self, troops: troops, targetEntity: controlledEntity)
        
        troopControlButtons = TroopControlButtons(size: self.size, troopControlSystem: troopControlSystem)
        if let camera = self.camera {
            camera.addChild(troopControlButtons)
        }
        
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
        
        let deltaTime = currentTime - (customLastUpdateTime ?? currentTime)
        customLastUpdateTime = currentTime
        if let agentComponent = controlledEntity.component(ofType: AgentComponent.self) {
            agentComponent.agent.update(deltaTime: deltaTime)
        }
        for troop in troops {
            if let agentComponent = troop.component(ofType: AgentComponent.self) {
                agentComponent.agent.update(deltaTime: deltaTime)
            }
        }
        
        for troop in troops {
            guard let behavior = troop.component(ofType: TroopBehaviorComponent.self),
                  let player = controlledEntity else { continue }
            if let enemy = nearestEnemyTroop(inRangeOf: troop) {
                if behavior.target !== enemy {
                    behavior.setTarget(enemy)
                }
            } else {
                if behavior.target !== player {
                    behavior.setTarget(player)
                }
            }
        }
        
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
        
        // --- Depth sorting: nodes with lower Y appear in front (higher zPosition) ---
        if let playerNode = controlledEntity.component(ofType: GKSKNodeComponent.self)?.node {
            // The base (e.g. 1000) must be high enough to keep all characters above the background
            playerNode.zPosition = 1000 - playerNode.position.y
        }
        for troop in troops {
            if let troopNode = troop.component(ofType: GKSKNodeComponent.self)?.node {
                troopNode.zPosition = 1000 - troopNode.position.y
            }
        }
    }
    
    // Removidos os métodos commandTroopsToFollow e commandTroopsToStop conforme instruções
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        
        touchHandler?.touchesBegan(touches, with: event)
        
        // Lógica dos controles virtuais
        if location.x <= 0 {
            virtualController?.setAnalogVisible(value: true)
            virtualController?.changePosition(location)
            virtualController?.touchBegan(touches, with: event)
        } else {
            // comandos do commandController (comentados)
        }
        
        // --- ADICIONADO: Dispara comandos de botão de tropa ---
        // Passa a posição do toque no sistema de coordenadas da câmera para troopControlButtons
        troopControlButtons.handleTouch(location)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        touchHandler?.touchesMoved(touches, with: event)
        
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
        touchHandler?.touchesEnded(touches, with: event)
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

extension GameScene {
    func setupRTSAiming() {
        let aimingSystem = AimingSystem(scene: self)
        self.aimingSystem = aimingSystem
        touchHandler = RTSTouchHandler(scene: self, aimingSystem: aimingSystem)
    }
}
