import SpriteKit
import BehindGameKit

extension Notification.Name {
    static let showHomeViewRequested = Notification.Name("ShowHomeViewRequested")
}

extension GameScene {
    func handleWin() {
        guard let camera = camera else { return }
        guard camera.childNode(withName: "WinOverlay") == nil else { return }

        let winOverlay = SKNode()
        winOverlay.name = "WinOverlay"
        winOverlay.zPosition = 1000

        // Background dark overlay
        let darkBackground = SKSpriteNode(color: .black, size: size)
        darkBackground.alpha = 0.8
        darkBackground.zPosition = 0
        winOverlay.addChild(darkBackground)

        // Menu background sprite
        let menuBackground = SKSpriteNode(imageNamed: "Menu_Background")
        menuBackground.name = "WinMenuBackground"
        menuBackground.position = CGPoint.zero
        menuBackground.zPosition = 1
        menuBackground.size = size
        winOverlay.addChild(menuBackground)

        // Title sprite
        let titleSprite = SKSpriteNode(imageNamed: "Win_Title")
        titleSprite.name = "WinTitle"
        titleSprite.position = CGPoint(x: 15, y: 100)
        titleSprite.setScale(0.3)
        titleSprite.texture?.filteringMode = .nearest
        titleSprite.zPosition = 2
        winOverlay.addChild(titleSprite)

        // Title pulse animation (scale 0.3 to 0.32 and back, repeated)
        let pulseUp = SKAction.scale(to: 0.32, duration: 0.35)
        let pulseDown = SKAction.scale(to: 0.3, duration: 0.35)
        let pulseSequence = SKAction.sequence([pulseUp, pulseDown])
        let pulseForever = SKAction.repeatForever(pulseSequence)
        titleSprite.run(pulseForever)

        // Animated star (reuse Star_Icon_1..4 animation from defeat)
        let starFrames = (1...4).map { SKTexture(imageNamed: "Star_Icon_\($0)") }
        let starNode = SKSpriteNode(texture: starFrames.first)
        starNode.name = "WinStar"
        starNode.position = CGPoint(x: 15, y: 0)
        starNode.zPosition = 2
        winOverlay.addChild(starNode)

        let starAnimation = SKAction.animate(with: starFrames, timePerFrame: 0.2)
        let starRepeat = SKAction.repeatForever(starAnimation)
        starNode.run(starRepeat)

        // Continue button (SKLabelNode)
        let continueButton = SKLabelNode(fontNamed: "CCPixelArcade-Joystick")
        continueButton.text = "Continue"
        continueButton.name = "ContinueButton"
        continueButton.fontSize = 24
        continueButton.fontColor = .yellow
        continueButton.position = CGPoint(x: 0, y: -100)
        continueButton.zPosition = 2
        winOverlay.addChild(continueButton)

        // Button blinking animation (fade out to 0.3 alpha and back)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
        let blinkForever = SKAction.repeatForever(blinkSequence)
        continueButton.run(blinkForever)

        // Snow particle emitter setup
        if let snowEmitter = SKEmitterNode(fileNamed: "Snow.sks")?.copy() as? SKEmitterNode {
            snowEmitter.name = "WinSnow"
            snowEmitter.position = CGPoint(x: 0, y: size.height / 2)
            snowEmitter.zPosition = 3
            snowEmitter.particlePositionRange.dx = size.width
            winOverlay.addChild(snowEmitter)
        }

        camera.addChild(winOverlay)
        depthSortNodes()
    }

    func tryHandleWinOverlayTouch(_ cameraSpaceLocation: CGPoint) -> Bool {
        guard let camera = camera else { return false }
        let nodesAtPoint = camera.nodes(at: cameraSpaceLocation)
        for node in nodesAtPoint {
            if node.name == "ContinueButton" {
                goToNextPhase()
                return true
            }
        }
        return false
    }

    private func goToNextPhase() {
        guard let view = self.view else { return }

        // Determine current scene name
        let currentSceneName = self.name ?? self.scene?.name ?? (self.userData?["SceneName"] as? String)

        let sceneManager = SceneManager()

        // Determine next scene based on currentSceneName
        var nextScene: GameScene?

        if let name = currentSceneName {
            switch name {
            case "GameScene_1":
                nextScene = sceneManager.phaseTwo()
            case "GameScene_2":
                // go to phase 3 if available; fallback to phase 2 or 1
                nextScene = sceneManager.phaseThree() ?? sceneManager.phaseTwo() ?? sceneManager.phaseOne()
            case "GameScene_3":
                // go to phase 4 if available; fallback to 3 or 2
                nextScene = sceneManager.phaseFour() ?? sceneManager.phaseThree() ?? sceneManager.phaseTwo()
            case "GameScene_4":
                // go to phase 5 if available; fallback to 4 or 3
                nextScene = sceneManager.phaseFive() ?? sceneManager.phaseFour() ?? sceneManager.phaseThree()
            case "GameScene_5":
                returnToHome()
            default:
                nextScene = sceneManager.phaseTwo()
            }
        } else {
            // Fallback if no scene name
            nextScene = sceneManager.phaseTwo()
        }

        if let next = nextScene {
            next.scaleMode = .aspectFill
            view.presentScene(next, transition: .fade(withDuration: 1.0))
        }
    }

    /// Returns to the HomeView screen from the game.
    /// This implementation clears the current scene and posts a notification
    /// that higher-level UIKit/SwiftUI code can observe to show `HomeView`.
    ///
    /// To use: Observe `Notification.Name.showHomeViewRequested` from the
    /// hosting view controller and present `HomeView` when received.
    private func returnToHome() {
        // Stop game activity
        self.isPaused = true
        self.removeAllActions()
        self.removeAllChildren()

        // Prepare a lightweight empty scene to clear SKView content smoothly
        if let skView = self.view {
            let emptyScene = SKScene(size: skView.bounds.size)
            emptyScene.scaleMode = .resizeFill
            skView.presentScene(emptyScene, transition: .fade(withDuration: 0.5))
        }

        // Notify the app layer to present HomeView
        NotificationCenter.default.post(name: .showHomeViewRequested, object: nil)
    }

    /// This function checks if win condition is met by verifying if any enemy spawner remains active.
    /// If no enemy spawners are left and the win overlay is not already presented, it calls handleWin().
    /// Should be called whenever a spawner is destroyed and optionally from update().
    func checkWinConditionAndHandleIfNeeded() {
        guard let camera = camera else { return }
        if camera.childNode(withName: "WinOverlay") != nil {
            // Already showing win overlay
            return
        }

        // Note: Avoid using SKEntityManager.shared.entities here due to access control.
        // We conservatively determine win state using visible spawner nodes in the scene.

        // Fallback SpriteKit nodes approach: check spawner nodes in the scene
        let activeSpawnerNodes: [SKNode]
        if let spawnerNames = sceneConfiguration?.spawners {
            activeSpawnerNodes = spawnerNames.compactMap { name in
                childNode(withName: name)
            }.filter { node in
                // Consider node active if it's in the scene and visible
                node.parent != nil && !node.isHidden
            }
        } else {
            // Check all nodes with names containing "Spawner"
            activeSpawnerNodes = children.filter { node in
                node.name?.contains("Spawner") == true && node.parent != nil && !node.isHidden
            }
        }

        if !activeSpawnerNodes.isEmpty {
            // Still active spawners found
            return
        }

        // No active enemy spawners found, trigger win overlay
        handleWin()
    }
}
