import SpriteKit
import BehindGameKit

extension GameScene {
    func handleDefeat() {
        guard camera?.childNode(withName: "DefeatOverlay") == nil else { return }
        isPaused = true

        let overlay = SKNode()
        overlay.name = "DefeatOverlay"
        overlay.zPosition = 11_000

        // Fundo escuro ocupa a tela da câmera
        let bg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8),
                              size: size)
        bg.name = "DefeatOverlayBG"
        bg.position = .zero
        bg.zPosition = 0
        overlay.addChild(bg)

        // Título "Defeat" agora como sprite do asset "Defeat_Title"
        let defeatTitle = SKSpriteNode(imageNamed: "Defeat_Title")
        defeatTitle.name = "DefeatTitle"
        defeatTitle.position = CGPoint(x: 15, y: 100)
        defeatTitle.setScale(0.3)
        defeatTitle.zPosition = 1
        // Mantém consistência com o filtro nearest usado no projeto
        defeatTitle.texture?.filteringMode = .nearest
        overlay.addChild(defeatTitle)

        // Botão "Restart"
        let restartLabel = SKLabelNode(text: "Restart")
        restartLabel.fontName = "CCPixelArcade-Joystick"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -50)
        restartLabel.name = "RestartButton"
        restartLabel.zPosition = 1
        overlay.addChild(restartLabel)

        camera?.addChild(overlay)
    }

    // Agora este método espera receber SEMPRE um ponto no espaço da CÂMERA.
    func tryHandleOverlayTouch(_ cameraSpaceLocation: CGPoint) -> Bool {
        guard let camera = camera else { return false }
        let nodesAtPoint = camera.nodes(at: cameraSpaceLocation)
        if nodesAtPoint.first(where: { $0.name == "RestartButton" }) != nil {
            restartGame()
            return true
        }
        return false
    }

    private func restartGame() {
        guard let view = self.view else { return }
        if let newScene = GameScene(fileNamed: "GameScene_1") {
            newScene.scaleMode = .aspectFill
            view.presentScene(newScene, transition: .fade(withDuration: 1.0))
        }
    }
}
