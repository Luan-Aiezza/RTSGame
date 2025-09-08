import SpriteKit
import BehindGameKit

extension GameScene {
    func handleDefeat() {
        guard camera?.childNode(withName: "DefeatOverlay") == nil else { return }
        isPaused = true

        let overlay = SKNode()
        overlay.name = "DefeatOverlay"
        overlay.zPosition = 11_000

        // Fundo escuro
        let bg = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6),
                              size: size)
        bg.position = .zero
        overlay.addChild(bg)

        // Texto "Defeat"
        let defeatLabel = SKLabelNode(text: "Defeat")
        defeatLabel.fontName = "Avenir-Black"
        defeatLabel.fontSize = 72
        defeatLabel.fontColor = .red
        defeatLabel.position = CGPoint(x: 0, y: 100)
        overlay.addChild(defeatLabel)

        // Botão "Restart"
        let restartLabel = SKLabelNode(text: "Restart")
        restartLabel.fontName = "Avenir-Heavy"
        restartLabel.fontSize = 48
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -50)
        restartLabel.name = "RestartButton"
        overlay.addChild(restartLabel)

        camera?.addChild(overlay)
    }

    func tryHandleOverlayTouch(_ location: CGPoint) -> Bool {
        guard let camera = camera else { return false }
        let nodesAtPoint = camera.nodes(at: location)
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
