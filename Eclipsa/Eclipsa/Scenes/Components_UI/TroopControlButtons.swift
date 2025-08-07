import SpriteKit

/// Este componente UI cria e gerencia os botões de controle de tropas, para serem adicionados ao SKCameraNode.
class TroopControlButtons: SKNode {
    private let followButton: SKSpriteNode
    private let releaseButton: SKSpriteNode
    
    var onFollow: (() -> Void)?
    var onRelease: (() -> Void)?
    
    init(size: CGSize) {
        // Tamanhos e posições relativas ao centro da câmera
        let buttonSize = CGSize(width: 64, height: 64)
        
        followButton = SKSpriteNode(color: .green, size: buttonSize)
        followButton.alpha = 0.7
        followButton.position = CGPoint(x: size.width/2 - 80, y: -size.height/2 + 160)
        followButton.zPosition = 1000
        followButton.name = "followButton"
        let followLabel = SKLabelNode(text: "Follow")
        followLabel.fontName = "Avenir-Black"
        followLabel.fontSize = 22
        followLabel.fontColor = .white
        followLabel.verticalAlignmentMode = .center
        followButton.addChild(followLabel)
        
        releaseButton = SKSpriteNode(color: .red, size: buttonSize)
        releaseButton.alpha = 0.7
        releaseButton.position = CGPoint(x: size.width/2 - 80, y: -size.height/2 + 80)
        releaseButton.zPosition = 1000
        releaseButton.name = "releaseButton"
        let releaseLabel = SKLabelNode(text: "Release")
        releaseLabel.fontName = "Avenir-Black"
        releaseLabel.fontSize = 22
        releaseLabel.fontColor = .white
        releaseLabel.verticalAlignmentMode = .center
        releaseButton.addChild(releaseLabel)
        
        super.init()
        
        addChild(followButton)
        addChild(releaseButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Deve ser chamado a partir dos touchesBegan da camera ou GameScene.
    func handleTouch(_ location: CGPoint) {
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "followButton" { onFollow?() }
            if node.name == "releaseButton" { onRelease?() }
        }
    }
}
