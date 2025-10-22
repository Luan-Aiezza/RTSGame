import SpriteKit
import BehindGameKit

extension Notification.Name {
    static let showHomeViewRequested = Notification.Name("ShowHomeViewRequested")
}

extension GameScene {
    func handleWin() {
        SKEntityManager.shared.removeAll()
        self.isPaused = true
        WaveManager.shared.pauseWaveSystem()
        self.pauseButtonDelegate?.showPauseButton(nil)
        guard let camera = camera else { return }
        
        let winScene = WinScene(size: self.size)
        winScene.scaleMode = .aspectFill
        winScene.nextPhaseHandler = goToNextPhase
        
            self.view?.presentScene(winScene, transition: .crossFade(withDuration: 0.5))
        
        depthSortNodes()
    }

    func tryHandleWinOverlayTouch(_ cameraSpaceLocation: CGPoint) -> Bool {
        guard let camera = camera else { return false }
        let nodesAtPoint = camera.nodes(at: cameraSpaceLocation)
        for node in nodesAtPoint {
            if node.name == "ContinueButton" {
                AudioManager.shared.playSound(named: "Effect_Confirm_1")
                goToNextPhase(view: self.view!)
                return true
            }
        }
        return false
    }

    private func goToNextPhase(view: SKView) {
print("chamei o gotonextphase")
        // Determine current scene name
        let currentSceneName = self.name ?? self.scene?.name ?? (self.userData?["SceneName"] as? String)
        print(currentSceneName)
        // Determine next scene based on currentSceneName
        var nextScene: SKScene?

        if let name = currentSceneName,
           let sceneManager = self.sceneManager{
            switch name {
            case "GameScene_0":
                sceneManager.flowController.goHome()
                GameCenterManager.shared.reportAchievement(identifier: "gameplay004")

            case "GameScene_1":
                GameCenterManager.shared.reportAchievement(identifier: "history001")
                nextScene = sceneManager.phaseTwo()
            case "GameScene_2":
                GameCenterManager.shared.reportAchievement(identifier: "history002")
                // go to phase 3 if available; fallback to phase 2 or 1
                nextScene = sceneManager.phaseThree() ?? sceneManager.phaseTwo() ?? sceneManager.phaseOne()
            case "GameScene_3":
                GameCenterManager.shared.reportAchievement(identifier: "history003")
                // go to phase 4 if available; fallback to 3 or 2
                nextScene = sceneManager.phaseFour() ?? sceneManager.phaseThree() ?? sceneManager.phaseTwo()
            case "GameScene_4":
                GameCenterManager.shared.reportAchievement(identifier: "history004")
                // go to phase 5 if available; fallback to 4 or 3
                nextScene = sceneManager.phaseFive() ?? sceneManager.phaseFour() ?? sceneManager.phaseThree()
            case "GameScene_5":
                GameCenterManager.shared.reportAchievement(identifier: "history005")
                nextScene = sceneManager.endScene(size: view.bounds.size)
                
            default:
                nextScene = sceneManager.phaseOne()
            }
        } else {
            // Fallback if no scene name
            nextScene = sceneManager?.phaseOne()
        }

        if let next = nextScene {
            if let scene = next as? GameScene {
                scene.pauseButtonDelegate = self.pauseButtonDelegate
            }
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
