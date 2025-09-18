import SpriteKit

/// Observa gerações de recursos dos Inhibitors e mostra um efeito visual "Solar_Fragment"
/// subindo acima do node da entidade e desaparecendo.
final class UISolarGeneratorComponent: SKNode {
    
    private let iconName = "Solar_Fragment"
    private let iconSize = CGSize(width: 32, height: 32)
    private let verticalRise: CGFloat = 28
    private let aboveOffset: CGFloat = 10
    private let duration: TimeInterval = 0.8
    
    override init() {
        super.init()
        self.name = "hudSolarGeneratorEffect"
        // Observa eventos de geração
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInhibitorGeneratedResource(_:)),
            name: .inhibitorDidGenerateResource,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleInhibitorGeneratedResource(_ note: Notification) {
        // Recupera o node do edifício para spawnar o efeito nele
        guard let node = note.userInfo?["node"] as? SKSpriteNode else { return }
        spawnEffect(above: node)
    }
    
    private func spawnEffect(above node: SKSpriteNode) {
        // Cria o sprite do fragmento
        let fragment = SKSpriteNode(imageNamed: iconName)
        fragment.size = iconSize
        fragment.anchorPoint = CGPoint(x: 0.5, y: 0.0) // base do sprite no ponto de partida
        fragment.alpha = 1.0
        fragment.texture?.filteringMode = .nearest
        
        // Posição inicial: um pouco acima do topo do node do Inhibitor
        let startY = (node.size.height / 2) + aboveOffset
        fragment.position = CGPoint(x: 0, y: startY)
        
        // Adiciona como filho do próprio node do Inhibitor (herda z/ordenação)
        node.addChild(fragment)
        
        // Anima: subir e fade out
        let moveUp = SKAction.moveBy(x: 0, y: verticalRise, duration: duration)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: duration)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        fragment.run(.sequence([group, remove]))
    }
}

