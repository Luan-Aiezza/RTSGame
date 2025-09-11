import SpriteKit
import GameplayKit
import BehindGameKit

/// Componente que indica na câmera quando uma estrutura aliada (Nexus/Inhibitor) está sendo atacada.
/// Exibe uma seta "Attack_Indicator" na borda da viewport apontando para a estrutura caso ela esteja fora da tela.
/// A indicação é mostrada por cerca de 1 segundo a cada detecção de dano.
public class IndicatorAttackComponent: GKComponent {
    
    // MARK: - Configuration
    private let indicatorAssetName = "Attack_Indicator"
    private let showDuration: TimeInterval = 1.0
    private let edgeInset: CGFloat = 24.0 // margem interna para posicionar na borda
    private let indicatorSize = CGSize(width: 32, height: 32)
    
    // MARK: - State
    private var indicatorNode: SKSpriteNode?
    private var hideAtTime: TimeInterval?
    private var lastHealth: Int?
    
    // Cache de acesso
    private var targetNode: SKNode? {
        entity?.component(ofType: GKSKNodeComponent.self)?.node
    }
    private var team: Team? {
        entity?.component(ofType: TeamComponent.self)?.team
    }
    
    // MARK: - Lifecycle
    public override func didAddToEntity() {
        super.didAddToEntity()
        setupHealthObservation()
    }
    
    public override func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        removeIndicatorNode()
    }
    
    // MARK: - Health observation
    private func setupHealthObservation() {
        guard let health = entity?.component(ofType: HealthComponent.self) else { return }
        lastHealth = health.currentHealth
        
        // Preserva callback anterior
        let previous = health.onHealthChanged
        health.onHealthChanged = { [weak self] current, max in
            previous?(current, max)
            self?.handleHealthChanged(current: current)
        }
    }
    
    private func handleHealthChanged(current: Int) {
        // Só reage para estruturas aliadas
        guard team == .sun else { return }
        guard let last = lastHealth else {
            lastHealth = current
            return
        }
        defer { lastHealth = current }
        
        // Detecta dano
        if current < last {
            showIndicatorIfOffscreen()
        }
    }
    
    // MARK: - Indicator logic
    private func showIndicatorIfOffscreen() {
        guard let scene = targetNode?.scene as? GameScene,
              let camera = scene.camera,
              let target = targetNode
        else { return }
        
        // Converte posição do alvo para o espaço da câmera
        let targetInCamera = target.convert(CGPoint.zero, to: camera)
        
        // Calcula bounds visíveis da câmera
        let viewSize = scene.size
        let scale = camera.xScale // assumindo escala uniforme
        let halfW = (viewSize.width * 0.5) / scale
        let halfH = (viewSize.height * 0.5) / scale
        let visibleRect = CGRect(x: -halfW, y: -halfH, width: halfW * 2, height: halfH * 2)
        
        // Se alvo está visível, não mostra a seta
        if visibleRect.contains(targetInCamera) {
            return
        }
        
        // Garante que o nó exista e esteja na câmera
        ensureIndicatorNode(on: camera)
        
        // Atualiza posição/rotação inicial e agenda hide
        updateIndicatorPositionAndRotation(targetInCamera: targetInCamera, visibleRect: visibleRect)
        hideAtTime = CACurrentMediaTime() + showDuration
        indicatorNode?.isHidden = false
        indicatorNode?.alpha = 1.0
        // Pequena animação de feedback (opcional)
        indicatorNode?.removeAction(forKey: "blink")
        let blink = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 0.15),
            .fadeAlpha(to: 1.0, duration: 0.15)
        ])
        indicatorNode?.run(.repeat(blink, count: 2), withKey: "blink")
    }
    
    private func ensureIndicatorNode(on camera: SKCameraNode) {
        if indicatorNode == nil {
            let sprite = SKSpriteNode(imageNamed: indicatorAssetName)
            sprite.size = indicatorSize
            sprite.zPosition = 10_000 // acima do HUD
            sprite.isHidden = true
            indicatorNode = sprite
        }
        if indicatorNode?.parent !== camera {
            camera.addChild(indicatorNode!)
        }
    }
    
    private func removeIndicatorNode() {
        indicatorNode?.removeAllActions()
        indicatorNode?.removeFromParent()
        indicatorNode = nil
    }
    
    /// Posiciona a seta na borda do retângulo visível, apontando para o alvo.
    private func updateIndicatorPositionAndRotation(targetInCamera: CGPoint, visibleRect: CGRect) {
        guard let indicator = indicatorNode else { return }
        
        // Direção do centro (0,0 no espaço da câmera) até o alvo
        let dir = CGVector(dx: targetInCamera.x, dy: targetInCamera.y)
        let angle = atan2(dir.dy, dir.dx)
        
        // Interseção do raio na direção 'angle' com o retângulo (clamp na borda)
        // Começa no centro (0,0) e vai na direção do alvo até tocar a borda do visibleRect.
        let clampedPoint = intersectionPointOnRectEdge(direction: dir, rect: visibleRect, inset: edgeInset)
        
        indicator.position = clampedPoint
        indicator.zRotation = angle - .pi / 2 // seta padrão apontando para cima -> ajusta para apontar para o alvo
    }
    
    /// Calcula o ponto na borda do retângulo na direção do vetor dir, com uma margem interna.
    private func intersectionPointOnRectEdge(direction dir: CGVector, rect: CGRect, inset: CGFloat) -> CGPoint {
        // Normaliza direção
        let len = max(0.0001, hypot(dir.dx, dir.dy))
        let ndx = dir.dx / len
        let ndy = dir.dy / len
        
        // Borda interna (inset)
        let minX = rect.minX + inset
        let maxX = rect.maxX - inset
        let minY = rect.minY + inset
        let maxY = rect.maxY - inset
        
        // Para cada borda, calcula t para interseção com a linha (0,0) + t*(ndx, ndy)
        var candidates: [CGPoint] = []
        
        if abs(ndx) > 0.0001 {
            // interseção com x = minX
            let t1 = minX / ndx
            let y1 = t1 * ndy
            if t1 > 0, y1 >= minY, y1 <= maxY {
                candidates.append(CGPoint(x: minX, y: y1))
            }
            // interseção com x = maxX
            let t2 = maxX / ndx
            let y2 = t2 * ndy
            if t2 > 0, y2 >= minY, y2 <= maxY {
                candidates.append(CGPoint(x: maxX, y: y2))
            }
        }
        if abs(ndy) > 0.0001 {
            // interseção com y = minY
            let t3 = minY / ndy
            let x3 = t3 * ndx
            if t3 > 0, x3 >= minX, x3 <= maxX {
                candidates.append(CGPoint(x: x3, y: minY))
            }
            // interseção com y = maxY
            let t4 = maxY / ndy
            let x4 = t4 * ndx
            if t4 > 0, x4 >= minX, x4 <= maxX {
                candidates.append(CGPoint(x: x4, y: maxY))
            }
        }
        
        // Escolhe o candidato mais próximo (menor t, equivalente a menor distância)
        if let best = candidates.min(by: { $0.lengthSquared < $1.lengthSquared }) {
            return best
        }
        
        // Fallback: clamp simples
        let clampedX = min(max(dir.dx, minX), maxX)
        let clampedY = min(max(dir.dy, minY), maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    // MARK: - Update
    public override func update(deltaTime seconds: TimeInterval) {
        guard let scene = targetNode?.scene as? GameScene,
              let camera = scene.camera,
              let indicator = indicatorNode,
              indicator.parent === camera
        else { return }
        
        // Esconde quando passar o tempo
        if let hideAt = hideAtTime, CACurrentMediaTime() >= hideAt {
            indicator.isHidden = true
            hideAtTime = nil
            return
        }
        
        // Se estiver visível, atualiza posição/rotação continuamente
        if !indicator.isHidden,
           let target = targetNode {
            let targetInCamera = target.convert(CGPoint.zero, to: camera)
            
            let viewSize = scene.size
            let scale = camera.xScale
            let halfW = (viewSize.width * 0.5) / scale
            let halfH = (viewSize.height * 0.5) / scale
            let visibleRect = CGRect(x: -halfW, y: -halfH, width: halfW * 2, height: halfH * 2)
            
            // Se alvo ficou visível, esconde imediatamente
            if visibleRect.contains(targetInCamera) {
                indicator.isHidden = true
                hideAtTime = nil
            } else {
                updateIndicatorPositionAndRotation(targetInCamera: targetInCamera, visibleRect: visibleRect)
            }
        }
    }
}

// MARK: - Small helpers
private extension CGPoint {
    var lengthSquared: CGFloat { x*x + y*y }
}
