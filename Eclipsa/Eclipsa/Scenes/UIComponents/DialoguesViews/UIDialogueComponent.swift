//
//  UIDialogueComponent.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 11/09/25.
//

import SpriteKit
import AVFoundation

struct DialogueLine {
    let text: String
    let portraitImageName: String? // mantemos por compatibilidade, mas não usamos
}

final class DialogueHUD: SKNode {
    private let backgroundBox: SKShapeNode
    private let textLabel: SKLabelNode
    private let starNode: SKSpriteNode
    
    private var fullText: String = ""
    private var typingTimer: Timer?
    private var currentCharIndex: Int = 0
    private var onTypingCompleted: (() -> Void)?
    private var nextAllowedSoundTime: TimeInterval = 0
    
    init(sceneSize: CGSize) {
        // Texto
        textLabel = SKLabelNode(text: "")
        textLabel.fontSize = 16
        textLabel.fontColor = .white
        textLabel.fontName = "PixelifySans-Regular"
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = sceneSize.width * 0.85
        textLabel.verticalAlignmentMode = .top
        textLabel.horizontalAlignmentMode = .left
        textLabel.zPosition = 10_510
        
        // Caixa preta com borda dourada
        backgroundBox = SKShapeNode()
        backgroundBox.fillColor = SKColor.black.withAlphaComponent(0.8)
        backgroundBox.strokeColor = SKColor.yellow.withAlphaComponent(0.8)
        backgroundBox.lineWidth = 1
        backgroundBox.zPosition = 10_500
        backgroundBox.isAntialiased = false // estilo pixel
        
        // Estrela animada
        let initialTexture = SKTexture(imageNamed: "Star_Icon_1")
        starNode = SKSpriteNode(texture: initialTexture, size: CGSize(width: 32, height: 32))
        starNode.zPosition = 10_520
        starNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        super.init()
        
        // Ajusta posição inicial para começar da esquerda
        let topY = sceneSize.height / 3
        textLabel.position = CGPoint(
            x: -(sceneSize.width * 0.82) / 2, // borda esquerda da caixa
            y: topY - 10
        )
        backgroundBox.position = CGPoint(x: 0, y: topY - 5)
        starNode.position = CGPoint(x: 0, y: topY + 25)
        
        addChild(backgroundBox)
        addChild(starNode)
        addChild(textLabel)
        
        alpha = 0.0
        isHidden = true
        
        startStarAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    func configure(line: DialogueLine) {
        fullText = line.text
        textLabel.text = ""
        currentCharIndex = 0
        updateBoxSize()
    }
    
    private func updateBoxSize() {
        // Calcula o tamanho necessário baseado no texto atual
        let labelFrame = textLabel.frame
        let padding: CGFloat = 20
        let width = labelFrame.width + padding
        let height = labelFrame.height + padding
        
        let rect = CGRect(
            x: -width/2,
            y: -height,
            width: width,
            height: height
        )
        backgroundBox.path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
    }
    
    func present(animated: Bool = true) {
        isHidden = false
        removeAllActions()
        run(.fadeAlpha(to: 1.0, duration: animated ? 0.25 : 0.0))
    }
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        typingTimer?.invalidate()
        typingTimer = nil
        removeAllActions()
        run(.fadeAlpha(to: 0.0, duration: animated ? 0.25 : 0.0)) {
            self.isHidden = true
            completion?()
        }
    }
    
    func startTypewriter(charInterval: TimeInterval = 0.03, onCompleted: @escaping () -> Void) {
        typingTimer?.invalidate()
        currentCharIndex = 0
        textLabel.text = ""
        onTypingCompleted = onCompleted
        nextAllowedSoundTime = 0
        
        guard !fullText.isEmpty else {
            onCompleted()
            return
        }
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: charInterval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.currentCharIndex < self.fullText.count {
                let idx = self.fullText.index(self.fullText.startIndex, offsetBy: self.currentCharIndex + 1)
                let substring = String(self.fullText[..<idx])

                // Character just revealed
                let newChar = self.fullText[self.fullText.index(self.fullText.startIndex, offsetBy: self.currentCharIndex)]

                self.textLabel.text = substring
                self.currentCharIndex += 1
                self.updateBoxSize() // ← atualiza a caixa conforme cresce

                // Play typing sound by time (every 0.5s) to avoid noisy audio
                let now = CACurrentMediaTime()
                if now >= self.nextAllowedSoundTime {
                    AudioManager.shared.playSound(named: "Effect_Text_1")
                    self.nextAllowedSoundTime = now + 0.15
                }
            } else {
                timer.invalidate()
                self.typingTimer = nil
                self.onTypingCompleted?()
            }
        }
        RunLoop.main.add(typingTimer!, forMode: .common)
    }
    
    private func startStarAnimation() {
        let textures = [
            SKTexture(imageNamed: "Star_Icon_1"),
            SKTexture(imageNamed: "Star_Icon_2"),
            SKTexture(imageNamed: "Star_Icon_3"),
            SKTexture(imageNamed: "Star_Icon_4"),
        ]
        let animate = SKAction.animate(with: textures, timePerFrame: 0.15, resize: false, restore: false)
        let forever = SKAction.repeatForever(animate)
        starNode.run(forever, withKey: "starLoop")
    }
    
    // Pula a digitação e mostra o texto completo imediatamente
    func skipTypewriter() {
        // Se não estiver digitando, não faz nada
        guard typingTimer != nil else { return }
        
        typingTimer?.invalidate()
        typingTimer = nil
        
        // Mostra o texto completo de uma vez
        textLabel.text = fullText
        updateBoxSize()
        
        // Garante que a animação da estrela continue
        if starNode.action(forKey: "starLoop") == nil {
            startStarAnimation()
        }
        
        // Chama o callback de conclusão, simulando o fim da digitação
        onTypingCompleted?()
    }

}
