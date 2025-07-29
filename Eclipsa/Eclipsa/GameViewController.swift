//
//  GameViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 28/07/25.
//

import UIKit
import SpriteKit
import GameplayKit
import GameController

class GameViewController: UIViewController {
    private var virtualController: GCVirtualController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupVirtualController()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene") {
            
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! GameScene? {
                
                // Copy gameplay related content over to the scene
                sceneNode.entities = scene.entities
                sceneNode.graphs = scene.graphs
                
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                
                // Present the scene
                let skView = SKView(frame: view.bounds)
                skView.translatesAutoresizingMaskIntoConstraints = false
                
                view.addSubview(skView)
                
                skView.presentScene(sceneNode)
                skView.ignoresSiblingOrder = true
                skView.showsFPS = true
                skView.showsNodeCount = true
                
                NSLayoutConstraint.activate([
                    skView.topAnchor.constraint(equalTo: view.topAnchor),
                    skView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                    skView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        virtualController?.disconnect()
        NotificationCenter.default.removeObserver(self)
    }
}


extension GameViewController: GameControllerProtocol {
    
    func setupVirtualController() {
            // Crie uma configuração para o controlador virtual
        let configuration = GCVirtualController.Configuration()
            
            // Define quais elementos do controlador você quer que sejam exibidos.
            // Por exemplo, você pode querer um D-pad e botões ABXY.
            configuration.elements = [GCInputLeftThumbstick, GCInputButtonA, GCInputButtonB]
            // Você pode adicionar mais elementos conforme sua necessidade:
            // GCInputDirectionPad, GCInputButtonX, GCInputButtonY, etc.

            // Crie o controlador virtual com a configuração
            virtualController = GCVirtualController(configuration: configuration)

            // Conecte o controlador. Isso fará com que ele apareça na tela.
            virtualController?.connect()

            // Opcional: Adicione um observador para saber quando o controlador é desconectado
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(virtualControllerDidDisconnect),
                                                   name: .GCControllerDidDisconnect,
                                                   object: nil)
        }
    
    @objc
    func virtualControllerDidDisconnect(notification: Notification) {
            if let disconnectedController = notification.object as? GCController,
               disconnectedController == virtualController?.controller {
                print("GCVirtualController foi desconectado.")
            }
        }
}
