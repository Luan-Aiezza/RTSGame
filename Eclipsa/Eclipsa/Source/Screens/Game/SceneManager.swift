//
//  SceneManager.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 16/09/25.
//

import GameplayKit
import UIKit

extension Notification.Name {
    static let stopBackgroundMusic = Notification.Name("StopBackgroundMusic")
}

struct SceneManager {
    
    var flowController: FlowController

    func phaseOne() -> GameScene? {
        let scene = makeScene(with: "GameScene_1")
        scene?.configureScene(with: Phase1())
        return scene
    }
    
    func phaseTwo() -> GameScene? {
        let scene = makeScene(with: "GameScene_2")
        scene?.configureScene(with: Phase2())
        return scene
    }
    
    func phaseThree() -> GameScene? {
        let scene = makeScene(with: "GameScene_3")
        scene?.configureScene(with: Phase3())
        return scene
    }
    
    func phaseFour() -> GameScene? {
        let scene = makeScene(with: "GameScene_4")
        scene?.configureScene(with: Phase4())
        return scene
    }
    
    func phaseFive() -> GameScene? {
        let scene = makeScene(with: "GameScene_5")
        scene?.configureScene(with: Phase5())
        return scene
    }
    
    func tutorial() -> GameScene? {
        let scene = makeScene(with: "GameScene_0")
        scene?.configureScene(with: Tutorial())
        return scene
    }
    
    private func makeScene(with name: String) -> GameScene? {
        guard let gkScene = GKScene(fileNamed: name),
              let sceneNode = gkScene.rootNode as? GameScene else { return nil}
            sceneNode.scaleMode = .aspectFill
            sceneNode.name = name
            sceneNode.sceneManager = self
            return sceneNode
    }
    
    func introScene(size: CGSize) -> IntroDialogueScene {
        let intro = IntroDialogueScene(size: size)
        intro.scaleMode = .aspectFill
        return intro
    }
    
    func endScene(size: CGSize) -> EndDialogueScene {
        let ending = EndDialogueScene(size: size)
        ending.scaleMode = .aspectFill
        NotificationCenter.default.post(name: .stopBackgroundMusic, object: nil)

        // Quando a cena de ending terminar, apresenta a UI de créditos (UIKit)
        ending.onFinished = { [flowController] in
            DispatchQueue.main.async {
                // Toca trilha de créditos (opcional)
                AudioManager.shared.fadeInBackgroundMusic(named: "OST_Credits")

                // Encontra o top-most UIViewController para apresentar a tela de créditos
                guard let topVC = SceneManager.topViewController() else {
                    // Se não encontrar, apenas volta para Home
                    AudioManager.shared.fadeOutBackgroundMusic()
                    flowController.goHome()
                    return
                }

                let creditsVC = CreditsViewController()
                creditsVC.modalPresentationStyle = .overFullScreen
                creditsVC.modalTransitionStyle = .crossDissolve

                creditsVC.onFinished = {
                    // Ao finalizar os créditos: parar música e aguardar 1s antes de voltar para Home
                    let preStopDelay: TimeInterval = 3.0
                    AudioManager.shared.fadeOutBackgroundMusic(duration: preStopDelay, stopAfter: true)

                    DispatchQueue.main.asyncAfter(deadline: .now() + preStopDelay) {
                        topVC.dismiss(animated: true) {
                            // Garante que qualquer música anterior esteja parada antes de iniciar a da Home
                            AudioManager.shared.stopBackgroundMusic()
                            flowController.goHome()
                        }
                    }
                }

                topVC.present(creditsVC, animated: true)
            }
        }

        return ending
    }
}

extension SceneManager {
    static func topViewController(base: UIViewController? = SceneManager.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }

    private static var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}




//import GameplayKit
//import UIKit
//import BehindGameKit
//
//extension Notification.Name {
//    static let stopBackgroundMusic = Notification.Name("StopBackgroundMusic")
//}
//
//struct SceneManager {
//
//    var flowController: FlowController
//
//    func phaseOne() -> GameScene? {
//        let scene = makeScene(with: "GameScene_1")
//        scene?.configureScene(with: Phase1())
//        return scene
//    }
//
//    func phaseTwo() -> GameScene? {
//        let scene = makeScene(with: "GameScene_2")
//        scene?.configureScene(with: Phase2())
//        return scene
//    }
//
//    func phaseThree() -> GameScene? {
//        let scene = makeScene(with: "GameScene_3")
//        scene?.configureScene(with: Phase3())
//        return scene
//    }
//
//    func phaseFour() -> GameScene? {
//        let scene = makeScene(with: "GameScene_4")
//        scene?.configureScene(with: Phase4())
//        return scene
//    }
//
//    func phaseFive() -> GameScene? {
//        let scene = makeScene(with: "GameScene_5")
//        scene?.configureScene(with: Phase5())
//        return scene
//    }
//
//    func tutorial() -> GameScene? {
//        let scene = makeScene(with: "GameScene_0")
//        scene?.configureScene(with: Tutorial())
//        return scene
//    }
//
//    private func makeScene(with name: String) -> GameScene? {
//        guard let gkScene = GKScene(fileNamed: name),
//              let sceneNode = gkScene.rootNode as? GameScene else { return nil}
//            resetAllGameElements()
//            sceneNode.scaleMode = .aspectFill
//            sceneNode.name = name
//            sceneNode.sceneManager = self
//
//            return sceneNode
//    }
//
//    func introScene(size: CGSize) -> IntroDialogueScene {
//        let intro = IntroDialogueScene(size: size)
//        intro.scaleMode = .aspectFill
//        return intro
//    }
//
//    func endScene(size: CGSize) -> EndDialogueScene {
//        let ending = EndDialogueScene(size: size)
//        ending.scaleMode = .aspectFill
//        NotificationCenter.default.post(name: .stopBackgroundMusic, object: nil)
//
//        // Quando a cena de ending terminar, apresenta a UI de créditos (UIKit)
//        ending.onFinished = { [flowController] in
//            DispatchQueue.main.async {
//                // Toca trilha de créditos (opcional)
//                AudioManager.shared.fadeInBackgroundMusic(named: "OST_Credits")
//
//                // Encontra o top-most UIViewController para apresentar a tela de créditos
//                guard let topVC = SceneManager.topViewController() else {
//                    // Se não encontrar, apenas volta para Home
//                    AudioManager.shared.fadeOutBackgroundMusic()
//                    flowController.goHome()
//                    return
//                }
//
//                let creditsVC = CreditsViewController()
//                creditsVC.modalPresentationStyle = .overFullScreen
//                creditsVC.modalTransitionStyle = .crossDissolve
//
//                creditsVC.onFinished = {
//                    // Ao finalizar os créditos: parar música e aguardar 1s antes de voltar para Home
//                    let preStopDelay: TimeInterval = 3.0
//                    AudioManager.shared.fadeOutBackgroundMusic(duration: preStopDelay, stopAfter: true)
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + preStopDelay) {
//                        topVC.dismiss(animated: true) {
//                            // Garante que qualquer música anterior esteja parada antes de iniciar a da Home
//                            AudioManager.shared.stopBackgroundMusic()
//                            flowController.goHome()
//                        }
//                    }
//                }
//
//                topVC.present(creditsVC, animated: true)
//            }
//        }
//
//        return ending
//    }
//
//    private func resetAllGameElements(){
//        WaveManager.shared.resetWaveSystem()
//        SKEntityManager.shared.removeAll()
//    }
//}
//
//extension SceneManager {
//    static func topViewController(base: UIViewController? = SceneManager.keyWindow?.rootViewController) -> UIViewController? {
//        if let nav = base as? UINavigationController {
//            return topViewController(base: nav.visibleViewController)
//        }
//        if let tab = base as? UITabBarController {
//            return topViewController(base: tab.selectedViewController)
//        }
//        if let presented = base?.presentedViewController {
//            return topViewController(base: presented)
//        }
//        return base
//    }
//
//    private static var keyWindow: UIWindow? {
//        return UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .flatMap { $0.windows }
//            .first { $0.isKeyWindow }
//    }
//}
//
