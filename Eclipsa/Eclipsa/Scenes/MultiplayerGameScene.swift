import Foundation
import Combine
import SpriteKit
import BehindGameKit
import GameplayKit

class MultiplayerGameScene: GameScene {
    // MARK: - Network
    var multipeerManager: MultiplayerSessionManager!

    // Jogador local e remoto
    var localPlayerTeam: Team = .sun
    var remotePlayerTeam: Team = .moon

    // Entidades de cada jogador
    var remoteControlledEntity: UnitEntity!

    override func sceneDidLoad() {
        super.sceneDidLoad()

        // Define o time local antes de criar player/tropas
        setupMultiplayerEnvironment()
        
        // Inicia conexão
        multipeerManager = MultiplayerSessionManager()
        multipeerManager.delegate = self
        multipeerManager.startHostingOrJoining()
    }

    func setupMultiplayerEnvironment() {
        // Cada jogador cria suas próprias estruturas e tropas iniciais
        setupPlayer(team: localPlayerTeam)
        setupOpponentBase(team: remotePlayerTeam)
    }

    func setupPlayer(team: Team) {
        controlledEntity = UnitEntity(team: team)
        SKEntityManager.shared.add(controlledEntity)
        setupRTSAiming()
        setupAdatpedVirtualController()
        physicsSystem.setupHeroPhysics(for: controlledEntity)
    }

    func setupOpponentBase(team: Team) {
        // Cria o Nexus e tropas iniciais do oponente
        addTroop(at: CGPoint(x: 500, y: 0), team: team)
        addTroop(at: CGPoint(x: 520, y: 30), team: team)
    }

    // MARK: - Sync
    func sendPlayerAction(_ action: PlayerAction) {
        if let data = try? JSONEncoder().encode(action) {
            multipeerManager.sendData(data)
        }
    }

    func receivePlayerAction(_ action: PlayerAction) {
        switch action {
        case .move(let point):
            // Calcula direção até o ponto remoto
            if let node = remoteControlledEntity.component(ofType: GKSKNodeComponent.self)?.node,
               let moveComponent = remoteControlledEntity.component(ofType: MovementComponent.self) {
                let direction = CGPoint(x: point.x - node.position.x,
                                        y: point.y - node.position.y)
                moveComponent.change(direction: direction)
            }

        case .spawnTroop(let type, let position):
            addTroop(at: position, team: remotePlayerTeam)
            
        case .attack(let targetID):
            break
        }
    }
}

enum PlayerAction: Codable {
    case move(point: CGPoint)
    case spawnTroop(type: String, position: CGPoint)
    case attack(targetID: String)
}

extension MultiplayerGameScene: MultiplayerSessionDelegate {
    func receivedData(_ data: Data) {
        if let action = try? JSONDecoder().decode(PlayerAction.self, from: data) {
            receivePlayerAction(action)
        }
    }
}
