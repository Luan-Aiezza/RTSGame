import SpriteKit
import Combine

/// HUD que exibe 1 ícone "Solar_Fragment" por unidade de recurso do jogador.
/// Alinha horizontalmente a partir do canto superior esquerdo da câmera.
final class UIResourceComponent: SKNode {
    
    // MARK: - Config
    private let iconName = "Solar_Fragment"
    private let iconSize = CGSize(width: 36, height: 36)
    private let horizontalSpacing: CGFloat = 4      // espaço entre ícones
    private let padding = CGPoint(x: 12, y: 24)     // margem do canto superior esquerdo
    private let maxIcons: Int                       // total de slots exibidos
    private weak var cameraNode: SKCameraNode?
    private weak var sceneRef: SKScene?
    
    // Opacidade dos ícones "vazios" (ajuste para 0.8 se quiser quase cheio)
    private let emptyAlpha: CGFloat = 0.5
    // Duração da animação ao preencher/esvaziar
    private let fillAnimationDuration: TimeInterval = 0.15
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    private var currentCount: Int = 0
    private var iconNodes: [SKSpriteNode] = []
    
    init(scene: SKScene, camera: SKCameraNode, maxIcons: Int = ResourceHandler.shared.getMaxAmountOfResources()) {
        self.sceneRef = scene
        self.cameraNode = camera
        self.maxIcons = maxIcons
        super.init()
        self.name = "hudResourceBar"
        self.zPosition = 10_600
        
        // Garante filtro nearest para manter pixel art nítido
        SKTexture(imageNamed: iconName).filteringMode = .nearest
        
        // Cria todos os slots uma única vez (sempre mostra maxIcons)
        createAllIconSlots()
        layoutIcons()
        
        // Observa mudanças nos recursos
        ResourceHandler.shared.$storedResources
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.applyResourceCount(newValue, animated: true)
            }
            .store(in: &cancellables)
        
        // Render inicial
        applyResourceCount(ResourceHandler.shared.getStoredResources(), animated: false)
        
        // Posicionamento inicial
        updatePosition()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func createAllIconSlots() {
        // Remove anteriores (se houver)
        iconNodes.forEach { $0.removeFromParent() }
        iconNodes.removeAll()
        
        for _ in 0..<maxIcons {
            let node = SKSpriteNode(imageNamed: iconName)
            node.size = iconSize
            node.anchorPoint = CGPoint(x: 0, y: 1) // canto superior esquerdo do próprio node
            node.zPosition = 0
            node.texture?.filteringMode = .nearest
            node.alpha = emptyAlpha
            addChild(node)
            iconNodes.append(node)
        }
    }
    
    // MARK: - Layout
    private func layoutIcons() {
        // Alinha um ao lado do outro a partir do (0,0) do container,
        // lembrando que o container será posicionado no canto sup. esquerdo da câmera.
        for (index, node) in iconNodes.enumerated() {
            let x = CGFloat(index) * (iconSize.width + horizontalSpacing)
            node.position = CGPoint(x: x, y: 0)
        }
    }
    
    /// Atualiza o estado visual (alpha) conforme a quantidade de recursos do jogador.
    private func applyResourceCount(_ count: Int, animated: Bool) {
        let clamped = max(0, min(count, maxIcons))
        
        // Atualiza cada slot conforme índice e quantidade atual
        for (index, node) in iconNodes.enumerated() {
            let shouldBeFilled = index < clamped
            let targetAlpha: CGFloat = shouldBeFilled ? 1.0 : emptyAlpha
            
            guard node.alpha != targetAlpha else { continue }
            
            if animated {
                node.removeAction(forKey: "fillFade")
                let action = SKAction.fadeAlpha(to: targetAlpha, duration: fillAnimationDuration)
                node.run(action, withKey: "fillFade")
            } else {
                node.alpha = targetAlpha
            }
        }
        
        currentCount = clamped
        // Também atualiza a posição do container em relação à câmera (caso necessário)
        updatePosition()
    }
    
    /// Reposiciona o container no canto superior esquerdo da câmera, respeitando padding e escala.
    func updatePosition() {
        guard let scene = sceneRef,
              let camera = cameraNode else { return }
        
        // Dimensão visível considerando escala da câmera
        let halfW = (scene.size.width * 0.5) / camera.xScale
        let halfH = (scene.size.height * 0.5) / camera.yScale
        
        // Queremos o canto superior esquerdo em coordenadas da câmera: (-halfW, +halfH)
        // Nosso node tem anchor default (0.5, 0.5). Para simplificar, posicionamos a base do container
        // exatamente no canto superior esquerdo + padding. Como os ícones têm anchor (0,1),
        // colocamos o container como referência desse canto e cada ícone parte de (0,0) para baixo/direita.
        let topLeft = CGPoint(x: -halfW + padding.x, y: halfH - padding.y)
        self.position = topLeft
    }
    
    // Chame este método quando a cena sofrer resize/rotação ou a escala da câmera mudar
    func handleCameraOrSceneChange() {
        updatePosition()
    }
}
