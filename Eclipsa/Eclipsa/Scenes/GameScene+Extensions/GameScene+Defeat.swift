import SpriteKit
import BehindGameKit

extension GameScene {
    func handleDefeat() {
        guard camera?.childNode(withName: "DefeatOverlay") == nil else { return }
        // Removido o pause global da cena para permitir animações do overlay
        // isPaused = true

        let overlay = SKNode()
        overlay.name = "DefeatOverlay"
        overlay.zPosition = 11_000
        overlay.isPaused = false

        // Plano de fundo com o asset "Menu_Background" para cobrir o jogo atrás
        let menuBG = SKSpriteNode(imageNamed: "Menu_Background")
        menuBG.name = "DefeatMenuBackground"
        menuBG.position = .zero
        menuBG.zPosition = -1 // atrás do fundo escuro
        // Ajusta para cobrir a viewport da câmera
        menuBG.size = size
        menuBG.texture?.filteringMode = .nearest
        overlay.addChild(menuBG)

        // Fundo escuro ocupa a tela da câmera (acima do Menu_Background)
        let bg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8),
                              size: size)
        bg.name = "DefeatOverlayBG"
        bg.position = .zero
        bg.zPosition = 0
        overlay.addChild(bg)

        // Partículas de neve (à frente do fundo escuro, atrás do título/botão)
        if let snowEmitter = SKEmitterNode(fileNamed: "SnowParticle.sks") {
            snowEmitter.name = "DefeatSnow" // nome claro para debug e depth sort
            // Como overlay está em espaço da câmera, usamos o tamanho da cena para cobrir a viewport
            let sceneSize = size
            // Emite do topo da viewport
            snowEmitter.position = CGPoint(x: 0, y: sceneSize.height / 2)
            // Largura total da viewport; leve variação vertical para garantir cobertura
            snowEmitter.particlePositionRange = CGVector(dx: sceneSize.width, dy: 10)
            // Deixe o emitter como filho do overlay; não precisamos de targetNode
            // snowEmitter.targetNode = overlay
            // zPosition relativo ao overlay (será ajustado pelo depthSort)
            snowEmitter.zPosition = 0.2
            overlay.addChild(snowEmitter)
        } else {
            // Log útil para detectar problemas de asset
            #if DEBUG
            print("Warning: SnowParticle.sks not found or failed to load.")
            #endif
        }

        // Título "Defeat" agora como sprite do asset "Defeat_Title"
        let defeatTitle = SKSpriteNode(imageNamed: "Defeat_Title")
        defeatTitle.name = "DefeatTitle"
        defeatTitle.position = CGPoint(x: 15, y: 100)
        defeatTitle.setScale(0.3)
        defeatTitle.zPosition = 1
        defeatTitle.texture?.filteringMode = .nearest
        overlay.addChild(defeatTitle)

        // Animação de pulsação do título (como em HomeView: 1.0 -> 1.08, 1.2s, easeInEaseOut, autoreverse, loop)
        let pulseUp = SKAction.scale(to: 0.3 * 1.08, duration: 1.2) // base scale é 0.3
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.3, duration: 1.2)
        pulseDown.timingMode = .easeInEaseOut
        let pulseLoop = SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown]))
        defeatTitle.run(pulseLoop, withKey: "pulse")

        // Ícone de estrela animado entre o título e o botão Restart
        let starTextures = [
            SKTexture(imageNamed: "Star_Icon_1"),
            SKTexture(imageNamed: "Star_Icon_2"),
            SKTexture(imageNamed: "Star_Icon_3"),
            SKTexture(imageNamed: "Star_Icon_4")
        ]
        starTextures.forEach { $0.filteringMode = .nearest }
        let starNode = SKSpriteNode(texture: starTextures.first)
        starNode.name = "DefeatStar"
        starNode.position = CGPoint(x: 0, y: 0) // entre y: 100 (título) e y: -100 (restart)
        starNode.zPosition = 1
        starNode.setScale(1.0)
        overlay.addChild(starNode)

        let starAnimate = SKAction.animate(with: starTextures, timePerFrame: 0.15, resize: false, restore: false)
        let starLoop = SKAction.repeatForever(starAnimate)
        starNode.run(starLoop, withKey: "starLoop")

        // Texto do botão muda se for GameScene_0 (tutorial)
        let restartKey = (self.name == "GameScene_0") ? "restartTutorial" : "restart"
        let restartLabel = SKLabelNode(text: NSLocalizedString(restartKey, comment: ""))
        restartLabel.fontName = "CCPixelArcade-Joystick"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .yellow
        restartLabel.position = CGPoint(x: 0, y: -100)
        restartLabel.name = "RestartButton"
        restartLabel.zPosition = 1
        overlay.addChild(restartLabel)

        // Animação de piscar do botão (como em HomeView: opacity 1.0 -> 0.2, 1.0s, autoreverse, loop)
        restartLabel.alpha = 1.0
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 1.0)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        fadeIn.timingMode = .easeInEaseOut
        let blinkLoop = SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
        restartLabel.run(blinkLoop, withKey: "blink")

        camera?.addChild(overlay)

        // Garante z-order consistente com as regras centralizadas
        depthSortNodes()
    }

    // Agora este método espera receber SEMPRE um ponto no espaço da CÂMERA.
    func tryHandleOverlayTouch(_ cameraSpaceLocation: CGPoint) -> Bool {
        guard let camera = camera else { return false }
        let nodesAtPoint = camera.nodes(at: cameraSpaceLocation)
        if nodesAtPoint.first(where: { $0.name == "RestartButton" }) != nil {
            AudioManager.shared.playSound(named: "Effect_Cancel_1")
            restartGame()
            return true
        }
        return false
    }

    private func restartGame() {
        guard let view = self.view else { return }

        if self.name == "GameScene_0" {
            // Tutorial: volta para Home
            sceneManager?.flowController.goHome()
        } else {
            // Fases normais: sempre volta para a Fase 1
            if let newScene = sceneManager?.phaseOne() {
                view.presentScene(newScene, transition: .fade(withDuration: 1.0))
            }
        }
    }
}
