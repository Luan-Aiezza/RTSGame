import SpriteKit

/// Este componente UI cria e gerencia os botões de controle de tropas, para serem adicionados ao SKCameraNode.
class TroopControlButtons: SKNode {
    private weak var troopControlSystem: TroopControlSystem?
    private let followButton: SKSpriteNode
    
    var onFollow: (() -> Void)?
    
    init(size: CGSize, troopControlSystem: TroopControlSystem? = nil) {
        self.troopControlSystem = troopControlSystem

        // Tamanhos e posições relativas ao centro da câmera
        let buttonSize = CGSize(width: 64, height: 64)
        
        followButton = SKSpriteNode(color: .green, size: buttonSize)
        followButton.alpha = 0.7
        followButton.position = CGPoint(x: size.width/2 - 80, y: -size.height/2 + 80)
        followButton.zPosition = 1000
        followButton.name = "followButton"
        let followLabel = SKLabelNode(text: "Follow")
        followLabel.fontName = "Avenir-Black"
        followLabel.fontSize = 22
        followLabel.fontColor = .white
        followLabel.verticalAlignmentMode = .center
        followButton.addChild(followLabel)
        
        super.init()
        
        addChild(followButton)
        
        self.onFollow = { [weak self] in
            self?.troopControlSystem?.commandTroopsToFollow()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Deve ser chamado a partir dos touchesBegan da camera ou GameScene.
    func handleTouch(_ location: CGPoint) {
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "followButton" { onFollow?() }
        }
    }
}
