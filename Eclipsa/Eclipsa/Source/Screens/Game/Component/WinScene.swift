//
//  WinView.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/10/25.
//

import SpriteKit
import BehindGameKit

class WinScene: SKScene {
    
    var nextPhaseHandler: ((_ view: SKView) -> Void)?
    
    let winOverlay = SKNode()
    
    private lazy var darkBackground: SKSpriteNode = {
        let node = SKSpriteNode(color: .black, size: self.size)
        node.alpha = 0.7
        node.zPosition = -1
        return node
    }()
    
    private var titleSprite: SKSpriteNode = {
        let titleSprite = SKSpriteNode(imageNamed: "Win_Title")
        titleSprite.name = "WinTitle"
        titleSprite.position = CGPoint(x: 0, y: 100)
        titleSprite.setScale(0.3)
        titleSprite.texture?.filteringMode = .nearest
        titleSprite.zPosition = 2
        
        let pulseUp = SKAction.scale(to: 0.32, duration: 0.35)
        let pulseDown = SKAction.scale(to: 0.3, duration: 0.35)
        let pulseSequence = SKAction.sequence([pulseUp, pulseDown])
        let pulseForever = SKAction.repeatForever(pulseSequence)
        titleSprite.run(pulseForever)
        
        return titleSprite
    }()
    
    private var starNode: SKSpriteNode = {
        let starFrames = (1...4).map { SKTexture(imageNamed: "Star_Icon_\($0)") }
        let starNode = SKSpriteNode(texture: starFrames.first)
        starNode.name = "WinStar"
        starNode.position = CGPoint(x: 0, y: -80)
        starNode.zPosition = 2
        let starAnimation = SKAction.animate(with: starFrames, timePerFrame: 0.2)
        let starRepeat = SKAction.repeatForever(starAnimation)
        starNode.run(starRepeat)
        
        return starNode
    }()
    
    private var continueButton: SKLabelNode = {
        let continueButton = SKLabelNode(fontNamed: "CCPixelArcade-Joystick")
        continueButton.text = NSLocalizedString("continue", comment: "")
        continueButton.name = "ContinueButton"
        continueButton.fontSize = 24
        continueButton.fontColor = .yellow
        continueButton.position = CGPoint(x: 0, y: -125)
        continueButton.zPosition = 2
        continueButton.isPaused = false
        
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
        let blinkForever = SKAction.repeatForever(blinkSequence)
        continueButton.run(blinkForever)
        
        return continueButton
    }()
    
    func setupScene() {
        let camera = SKCameraNode()
        camera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(camera)
        self.camera = camera
        
        winOverlay.addChild(darkBackground)
        winOverlay.addChild(titleSprite)
        winOverlay.addChild(starNode)
        winOverlay.addChild(continueButton)
        setupSnowEmitter()
        camera.addChild(winOverlay)
    }
    
    func setupSnowEmitter() {
        if let snowEmitter = SKEmitterNode(fileNamed: "SnowParticle.sks")?.copy() as? SKEmitterNode {
            print("snow Emiter exists")
            snowEmitter.name = "WinSnow"
            snowEmitter.position = CGPoint(x: 0, y: size.height)
            snowEmitter.zPosition = 1001
            snowEmitter.particlePositionRange.dx = size.width
            camera?.addChild(snowEmitter)
        }
    }
    
    func tryHandleWinOverlayTouch(_ cameraSpaceLocation: CGPoint) -> Bool {
        guard let camera = camera else { return false }
        let nodesAtPoint = camera.nodes(at: cameraSpaceLocation)
        for node in nodesAtPoint {
            if node.name == "ContinueButton" {
                AudioManager.shared.playSound(named: "Effect_Confirm_1")
                nextPhaseHandler?(view!)
                return true
            }
        }
        return false
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first,
           let camera {
            let location = touch.location(in: camera)
            
            _ = tryHandleWinOverlayTouch(location)
        }
    }
}
