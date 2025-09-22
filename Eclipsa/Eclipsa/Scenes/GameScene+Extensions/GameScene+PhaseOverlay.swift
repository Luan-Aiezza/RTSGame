import SpriteKit

extension GameScene {
    // Exibe a overlay de início de fase (carregamento)
    // currentPhase: fase para a qual estamos indo (1...5)
    // previousPhase: fase de onde viemos (1...5). Se nil, começa direto na currentPhase (sem animar).
    func showPhaseOverlay(currentPhase: Int = 1, previousPhase: Int? = nil) {
        guard camera?.childNode(withName: "PhaseOverlay") == nil else { return }
        guard let camera = self.camera else { return }
        
        let clampedCurrent = max(1, min(5, currentPhase))
        let clampedPrevious = previousPhase.map { max(1, min(5, $0)) }
        
        let overlay = SKNode()
        overlay.name = "PhaseOverlay"
        overlay.zPosition = 11_000
        overlay.isPaused = false
        
        // Fundo preto (atrás de tudo do overlay)
        let bg = SKSpriteNode(color: .black, size: size)
        bg.name = "PhaseOverlayBG"
        bg.position = .zero
        bg.zPosition = 0.0
        overlay.addChild(bg)
        
        // Partículas de neve (à frente do fundo preto)
        if let snowEmitter = SKEmitterNode(fileNamed: "SnowParticle.sks") {
            snowEmitter.name = "PhaseSnow"
            let sceneSize = size
            snowEmitter.position = CGPoint(x: 0, y: sceneSize.height / 2)
            snowEmitter.particlePositionRange = CGVector(dx: sceneSize.width, dy: 10)
            snowEmitter.zPosition = 2
            overlay.addChild(snowEmitter)
        } else {
            #if DEBUG
            print("Warning: SnowParticle.sks not found or failed to load (PhaseOverlay).")
            #endif
        }
        
        let title = SKLabelNode(text: NSLocalizedString("title", comment: ""))
        title.name = "PhaseTitle"
        title.fontName = "CCPixelArcade-Display"
        title.fontSize = 28
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 150)
        title.zPosition = 1.0
        overlay.addChild(title)
        
        // 5 ícones de fase em linha (abaixo do título/coroa) — subidos e com espaçamento dobrado
        let phaseIconNames = (1...5).map { "Transition_Phase_Icon_\($0)" }
        let iconsY: CGFloat = 50
        let spacing: CGFloat = 16
        var iconNodes: [SKSpriteNode] = []
        for name in phaseIconNames {
            let node = SKSpriteNode(imageNamed: name)
            node.name = "PhaseIcon" // base; renomearemos com índice
            node.texture?.filteringMode = .nearest
            node.zPosition = 1.0
            node.setScale(0.1)
            iconNodes.append(node)
            overlay.addChild(node)
        }
        // Layout horizontal centralizado
        let totalWidth = iconNodes.reduce(0) { $0 + $1.size.width } + spacing * CGFloat(max(iconNodes.count - 1, 0))
        var currentX = -totalWidth / 2
        var phaseIconPositions: [Int: CGPoint] = [:]
        for (idx, node) in iconNodes.enumerated() {
            node.position = CGPoint(x: currentX + node.size.width / 2, y: iconsY)
            node.name = "PhaseIcon_\(idx + 1)" // ex: PhaseIcon_1 ... PhaseIcon_5
            phaseIconPositions[idx + 1] = node.position
            currentX += node.size.width + (idx < iconNodes.count - 1 ? spacing : 0)
        }
        
        // Animação de pulsação nos ícones (igual ao título do HomeView: 1.0 -> 1.08, 1.2s, autoreverse, loop)
        let baseScale: CGFloat = 0.1
        let targetScale: CGFloat = baseScale * 1.08
        let pulseUp = SKAction.scale(to: targetScale, duration: 1.2)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: baseScale, duration: 1.2)
        pulseDown.timingMode = .easeInEaseOut
        let pulseLoop = SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown]))
        iconNodes.forEach { $0.run(pulseLoop, withKey: "phaseIconPulse") }
        
        // Coroa acima do ícone da fase anterior (ou da atual se não houver anterior)
        let crown = SKSpriteNode(imageNamed: "Transition_Crown_Icon")
        crown.name = "PhaseCrown"
        crown.zPosition = 1.0
        crown.setScale(0.05)
        crown.texture?.filteringMode = .nearest
        
        // Offset vertical da coroa para ficar "acima" do ícone
        let crownOffsetY: CGFloat = 48
        
        // Posição inicial (previous ou current)
        let startPhase = clampedPrevious ?? clampedCurrent
        let startPos = phaseIconPositions[startPhase] ?? .zero
        crown.position = CGPoint(x: startPos.x, y: startPos.y + crownOffsetY)
        overlay.addChild(crown)
        
        // Se há transição (previous != current), animar a coroa até a posição do ícone da currentPhase
        if clampedPrevious != nil, clampedPrevious != clampedCurrent,
           let targetPos = phaseIconPositions[clampedCurrent] {
            let endPoint = CGPoint(x: targetPos.x, y: targetPos.y + crownOffsetY)
            let move = SKAction.move(to: endPoint, duration: 0.6)
            move.timingMode = .easeInEaseOut
            crown.run(move, withKey: "moveToCurrentPhase")
        }
        
        // Animação da garota caminhando (mais abaixo)
        let girlTextures: [SKTexture] = (1...4).map { SKTexture(imageNamed: "Transition_Walk_Girl_\($0)") }
        girlTextures.forEach { $0.filteringMode = .nearest }
        if let first = girlTextures.first {
            let girl = SKSpriteNode(texture: first)
            girl.name = "PhaseGirl"
            girl.position = CGPoint(x: 0, y: -80)
            girl.zPosition = 1.0
            girl.setScale(0.1)
            overlay.addChild(girl)
            
            if girlTextures.count >= 2 {
                let animate = SKAction.animate(with: girlTextures, timePerFrame: 0.15, resize: false, restore: false)
                let loop = SKAction.repeatForever(animate)
                girl.run(loop, withKey: "walkLoop")
            }
        }
        
        // Adiciona na câmera
        camera.addChild(overlay)
        
        // Garante z-order conforme regras centralizadas
        depthSortNodes()
    }
    
    // Remover a overlay (quando terminar de carregar a fase) com fade-out
    func hidePhaseOverlay() {
        guard let overlay = camera?.childNode(withName: "PhaseOverlay") else { return }
        overlay.removeAction(forKey: "phaseOverlayFade")
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.35)
        overlay.run(fadeOut, completion: {
            overlay.removeFromParent()
        })
    }
    
    /// Extrai o número da fase a partir do nome da cena (ex: "GameScene_3" → 3).
    private func extractPhaseNumber(from sceneName: String?) -> Int {
        guard let name = sceneName else { return 1 }
        let components = name.split(separator: "_")
        if let last = components.last, let number = Int(last) {
            return max(1, min(5, number)) // clamp entre 1 e 5
        }
        return 1
    }

    /// Mostra a overlay de fase baseada no nome da cena
    func showPhaseOverlayFromSceneName() {
        let current = extractPhaseNumber(from: self.name ?? self.scene?.name)
        let previous = max(1, current - 1)
        showPhaseOverlay(currentPhase: current, previousPhase: previous)
    }
}
