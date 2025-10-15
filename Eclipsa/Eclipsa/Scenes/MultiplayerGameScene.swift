//
//  MultiplayerGameScene.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 09/10/25.
//

import SpriteKit
import GameKit
import BehindGameKit
import GameplayKit
import Combine

public func lerp(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat { a + (b - a) * t }

final class MultiplayerGameScene: GameScene {
    private(set) var match: GKMatch?
    public var localTeam: Team = .sun
    public var remoteTeam: Team = .moon
    
    public var remotePlayerEntity: UnitEntity?
    
    // Identificador para sincronização
    public var localPlayerID: String = GKLocalPlayer.local.gamePlayerID
    public var remotePlayer: GKPlayer?

    // Remote smoothing targets
    public var remoteTargetPosition: CGPoint?
    public var remoteTargetRotation: CGFloat?

    // Troop ID management
    public var nextLocalTroopID: UInt32 = 1
    public var troopNodesByID: [UInt32: GKSKNodeComponent] = [:]
    public var troopTeamByID: [UInt32: Team] = [:]

    // MARK: - Init
    init(size: CGSize, match: GKMatch) {
        self.match = match
        super.init(size: size)
        scaleMode = .resizeFill
        match.delegate = self
    }

    /// Inicializador usado quando a cena é carregada via .sks ou storyboard.
    /// Evita crash ao usar `SKScene(fileNamed:)` ou carregamento automático do GameKit.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
    }

    // MARK: - Setup após criação
    /// Deve ser chamado logo após a cena ser criada, caso o `match` ainda não exista.
    func configure(with match: GKMatch) {
        self.match = match
        match.delegate = self
        configureTeams()
    }
    
    

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        print("🕹️ MultiplayerGameScene iniciada")

        // Se ainda não há match, espere até ser configurado
        guard let match = match else {
            print("⚠️ Match ainda não configurado. Chame `configure(with:)` antes de apresentar a cena.")
            return
        }

        // 1️⃣ Define os times com base na ordem de conexão
        configureTeams()
        
        // 2️⃣ Carrega conteúdo visual do arquivo .sks (se existir)
        if let path = Bundle.main.path(forResource: "MultiplayerGameScene", ofType: "sks"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SKScene.self, from: data) {
            for node in unarchived.children {
                addChild(node)
            }
        }
        
        // 3️⃣ Cria estruturas e entidades principais
        setupMultiplayerStructures()
        
        // 4️⃣ Cria jogadores locais e remotos
        setupPlayers()
        
        // 5️⃣ Configura interface e câmera
        setupCamera()
//        setupUI()
        rewireButtonsForMultiplayer()
        setupRTSAiming()
        
        
        print("✅ MultiplayerGameScene pronta com times: \(localTeam) vs \(remoteTeam)")
    }
    
    // ✅ NOVA FUNÇÃO
    private func rewireButtonsForMultiplayer() {
        // A essa altura, `super.didMove` já criou os botões.
        // Nós apenas trocamos o que eles fazem.
        
        buttons.invokeMeleeButton?.onTouch = { [weak self] in
            self?.invokeTroop(type: .melee)
        }
        
        buttons.invokeRangedButton?.onTouch = { [weak self] in
            // Adapte conforme sua necessidade
            // Ex: self?.invokeTroop(type: .ranged)
        }
    }
    
}
