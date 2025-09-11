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
    private let maxIcons: Int                       // opcionalmente limitar pelos recursos máximos
    private weak var cameraNode: SKCameraNode?
    private weak var sceneRef: SKScene?
    
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
        
        // Observa mudanças nos recursos
        ResourceHandler.shared.$storedResources
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.updateIcons(count: newValue)
            }
            .store(in: &cancellables)
        
        // Render inicial
        updateIcons(count: ResourceHandler.shared.getStoredResources())
        
        // Posicionamento inicial
        updatePosition()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    private func updateIcons(count: Int) {
        let clamped = max(0, min(count, maxIcons))
        guard clamped != currentCount else {
            // Mesmo número, apenas garante posição
            updatePosition()
            return
        }
        currentCount = clamped
        
        // Ajusta número de nós para bater com currentCount
        if clamped > iconNodes.count {
            // Adiciona nós faltantes
            let toAdd = clamped - iconNodes.count
            for _ in 0..<toAdd {
                let node = SKSpriteNode(imageNamed: iconName)
                node.size = iconSize
                node.anchorPoint = CGPoint(x: 0, y: 1) // canto superior esquerdo do próprio node
                node.zPosition = 0
                node.texture?.filteringMode = .nearest
                addChild(node)
                iconNodes.append(node)
            }
        } else if clamped < iconNodes.count {
            // Remove excedentes
            let toRemove = iconNodes.count - clamped
            let removed = iconNodes.suffix(toRemove)
            removed.forEach { $0.removeFromParent() }
            iconNodes.removeLast(toRemove)
        }
        
        // Reposiciona todos os ícones
        layoutIcons()
        // Também atualiza a posição do container em relação à câmera
        updatePosition()
    }
    
    private func layoutIcons() {
        // Alinha um ao lado do outro a partir do (0,0) do container,
        // lembrando que o container será posicionado no canto sup. esquerdo da câmera.
        for (index, node) in iconNodes.enumerated() {
            let x = CGFloat(index) * (iconSize.width + horizontalSpacing)
            node.position = CGPoint(x: x, y: 0)
        }
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

