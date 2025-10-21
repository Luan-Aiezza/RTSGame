//
//  EndDialogueScene.swift
//  Eclipsa
//
//  Created by Assistant on 17/09/25.
//

import SpriteKit

// Scene responsável por exibir a cena de encerramento da história após a fase 5
final class EndDialogueScene: SKScene {
    private var dialogueHUD: DialogueHUD!
    private var paragraphs: [DialogueLine] = []
    private var currentIndex: Int = 0
    private var isPresentingParagraph = false
    private var hasEnded = false
    private var isTypewriterRunning = false
    
    // Aplica estilo local do texto apenas nesta cena
    private func applyLocalTextStyling() {
        guard let hud = dialogueHUD else { return }
        func traverse(node: SKNode) {
            if let label = node as? SKLabelNode {
                label.fontSize = 20
            }
            for child in node.children { traverse(node: child) }
        }
        traverse(node: hud)
    }
    
    // Configurações
    private let perParagraphVisibleDuration: TimeInterval = 3.0
    private let typeCharInterval: TimeInterval = 0.05
    
    // Callback para quando terminar o final
    var onFinished: (() -> Void)?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        isUserInteractionEnabled = true // habilitar interação para skip
        setupParagraphs()
        setupHUD()
        presentNextParagraph()
    }
    
    private func setupHUD() {
        let halfWidthSize = CGSize(width: size.width * 0.8, height: size.height)
        dialogueHUD = DialogueHUD(sceneSize: halfWidthSize)
        dialogueHUD.position = CGPoint(x: size.width/2, y: size.height * 0.001)
        addChild(dialogueHUD)
        applyLocalTextStyling()
        
        if let box = (dialogueHUD.children.first { $0 is SKShapeNode }) as? SKShapeNode {
            box.fillColor = .clear
            box.strokeColor = .clear
        }
        dialogueHUD.present(animated: true)
    }
    
    private func setupParagraphs() {
        let texts: [String] = (0...4).map {
            NSLocalizedString("paragraph.\($0)", comment: "")
        }
        paragraphs = texts.map { DialogueLine(text: $0, portraitImageName: nil) }
    }
    
    private func presentNextParagraph() {
        guard currentIndex < paragraphs.count else {
            endDialogue()
            return
        }
        isPresentingParagraph = true
        let line = paragraphs[currentIndex]
        dialogueHUD.configure(line: line)
        applyLocalTextStyling()
        dialogueHUD.present(animated: true)
        
        isTypewriterRunning = true
        dialogueHUD.startTypewriter(charInterval: typeCharInterval) { [weak self] in
            guard let self = self else { return }
            self.isTypewriterRunning = false
            self.run(.wait(forDuration: self.perParagraphVisibleDuration)) { [weak self] in
                guard let self = self else { return }
                self.dialogueHUD.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.currentIndex += 1
                    self.isPresentingParagraph = false
                    self.run(.wait(forDuration: 0.35)) { [weak self] in
                        self?.dialogueHUD.present(animated: true)
                        self?.presentNextParagraph()
                    }
                }
            }
        }
    }
    
    private func completeTypewriterIfNeeded() {
        if isTypewriterRunning {
            dialogueHUD.skipTypewriter()
            isTypewriterRunning = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if hasEnded {
            return
        }
        
        if isTypewriterRunning {
            completeTypewriterIfNeeded()
            return
        }
        
        if isPresentingParagraph {
            dialogueHUD.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.currentIndex += 1
                self.isPresentingParagraph = false
                self.run(.wait(forDuration: 0.35)) { [weak self] in
                    self?.dialogueHUD.present(animated: true)
                    self?.presentNextParagraph()
                }
            }
            return
        }
    }
    
    private func endDialogue() {
        
        // 🔑 Reset do progresso salvo
        UserDefaults.standard.clearGameState()
        
        guard !hasEnded else { return }
        hasEnded = true
        let fade = SKAction.fadeOut(withDuration: 0.75)
        run(fade) { [weak self] in
            self?.onFinished?()
        }
    }
}
