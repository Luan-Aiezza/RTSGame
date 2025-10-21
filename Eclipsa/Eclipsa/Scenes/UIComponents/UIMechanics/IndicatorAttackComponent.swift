import SpriteKit
import GameplayKit
import BehindGameKit
#if os(iOS)
import UIKit // NOVO: Importa UIKit para acessar os Haptics
#endif

public class IndicatorAttackComponent: GKComponent {
    
    // MARK: - Configuration
    private let indicatorAssetName = "Attack_Indicator"
    private let showDuration: TimeInterval = 1.0
    private let edgeInset: CGFloat = 24.0 // margem interna para posicionar na borda
    private let indicatorSize = CGSize(width: 32, height: 32)
    
    // MARK: - Haptics (NOVO)
    #if os(iOS)
    // NOVO: Gerador de feedback háptico.
    // Usamos .warning, pois é um alerta de que sua base está sob ataque.
    private let hapticGenerator = UINotificationFeedbackGenerator()
    #endif
    
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
        
        #if os(iOS)
        // NOVO: Prepara o motor háptico para reduzir a latência na primeira vibração.
        hapticGenerator.prepare()
        #endif
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
    
    // MARK: - Haptics Trigger (NOVO)
    private func triggerHapticFeedback() {
        #if os(iOS)
        // NOVO: Dispara a vibração de "aviso"
        hapticGenerator.notificationOccurred(.warning)
        
        // NOVO: Prepara novamente para a próxima possível vibração
        hapticGenerator.prepare()
        #endif
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
        
        // NOVO: Aciona a vibração aqui!
        // Ocorre apenas se a entidade tomou dano E está fora da tela.
        triggerHapticFeedback()
        
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
        // Se estiver em outra árvore de nós (ex: antiga câmera), reparenta para a câmera atual.
        if indicatorNode?.parent !== camera {
            indicatorNode?.removeFromParent()
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
        let clampedPoint = intersectionPointOnRectEdge(direction: dir, rect: visibleRect, inset: edgeInset)
        
        indicator.position = clampedPoint
        indicator.zRotation = angle - .pi / 2
    }
    
    private func intersectionPointOnRectEdge(direction dir: CGVector, rect: CGRect, inset: CGFloat) -> CGPoint {
        let len = max(0.0001, hypot(dir.dx, dir.dy))
        let ndx = dir.dx / len
        let ndy = dir.dy / len
        
        let minX = rect.minX + inset
        let maxX = rect.maxX - inset
        let minY = rect.minY + inset
        let maxY = rect.maxY - inset
        
        var candidates: [CGPoint] = []
        
        if abs(ndx) > 0.0001 {
            let t1 = minX / ndx
            let y1 = t1 * ndy
            if t1 > 0, y1 >= minY, y1 <= maxY { candidates.append(CGPoint(x: minX, y: y1)) }
            let t2 = maxX / ndx
            let y2 = t2 * ndy
            if t2 > 0, y2 >= minY, y2 <= maxY { candidates.append(CGPoint(x: maxX, y: y2)) }
        }
        if abs(ndy) > 0.0001 {
            let t3 = minY / ndy
            let x3 = t3 * ndx
            if t3 > 0, x3 >= minX, x3 <= maxX { candidates.append(CGPoint(x: x3, y: minY)) }
            let t4 = maxY / ndy
            let x4 = t4 * ndx
            if t4 > 0, x4 >= minX, x4 <= maxX { candidates.append(CGPoint(x: x4, y: maxY)) }
        }
        
        if let best = candidates.min(by: { $0.lengthSquared < $1.lengthSquared }) {
            return best
        }
        
        let clampedX = min(max(dir.dx, minX), maxX)
        let clampedY = min(max(dir.dy, minY), maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    // MARK: - Update
    public override func update(deltaTime seconds: TimeInterval) {
        // 1) Se o alvo/nó foi removido ou a entidade sumiu -> limpa e remove componente
        let targetIsMissing = (targetNode == nil) || (targetNode?.parent == nil) || (targetNode?.scene == nil)
        if entity == nil || targetIsMissing {
            if indicatorNode != nil {
                print("[IndicatorAttackComponent] target missing or entity gone -> cleaning up indicator")
                removeIndicatorNode()
            }
            // Remove o componente da entidade para evitar ficar ativo
            if let ent = entity {
                ent.removeComponent(ofType: IndicatorAttackComponent.self)
            }
            return
        }
        
        // 2) Agora garantimos que temos scene + camera
        guard let scene = targetNode?.scene as? GameScene,
              let camera = scene.camera
        else {
            return
        }
        
        // 3) Se o indicatorNode existe mas não está anexado a câmera atual, reanexa
        if let indicator = indicatorNode, indicator.parent !== camera {
            camera.addChild(indicator)
        }
        
        // 4) Segue com lógica normal de esconder/atualizar
        guard let indicator = indicatorNode, indicator.parent === camera else { return }
        
        if let hideAt = hideAtTime, CACurrentMediaTime() >= hideAt {
            indicator.isHidden = true
            hideAtTime = nil
            return
        }
        
        if !indicator.isHidden, let target = targetNode {
            let targetInCamera = target.convert(CGPoint.zero, to: camera)
            
            let viewSize = scene.size
            let scale = camera.xScale
            let halfW = (viewSize.width * 0.5) / scale
            let halfH = (viewSize.height * 0.5) / scale
            let visibleRect = CGRect(x: -halfW, y: -halfH, width: halfW * 2, height: halfH * 2)
            
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
