//
//  IntroDialogueScene.swift
//  Eclipsa
//
//  Created by Assistant on 15/09/25.
//

import SpriteKit

// Scene responsável por exibir a introdução com parágrafos e efeito de máquina de escrever
final class IntroDialogueScene: SKScene {
    private var dialogueHUD: DialogueHUD!
    private var paragraphs: [DialogueLine] = []
    private var currentIndex: Int = 0
    private var isPresentingParagraph = false
    private var skipLabel: SKLabelNode?
    private var hasEnded = false
    
    // Aplica estilo local do texto apenas nesta cena
    private func applyLocalTextStyling() {
        guard let hud = dialogueHUD else { return }
        // Percorre recursivamente os nós para encontrar SKLabelNode e ajustar tamanho
        func traverse(node: SKNode) {
            if let label = node as? SKLabelNode {
                label.fontSize = 20
            }
            for child in node.children { traverse(node: child) }
        }
        traverse(node: hud)
    }
    
    // Configurações
    private let perParagraphVisibleDuration: TimeInterval = 8.0 // cada parágrafo permanece 10s na tela
    private let typeCharInterval: TimeInterval = 0.05 // velocidade de digitação
    
    // Callback para quando terminar a introdução
    var onFinished: (() -> Void)?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        isUserInteractionEnabled = true
        setupParagraphs()
        setupHUD()
        presentNextParagraph()
        setupSkipButton()
    }
    
    private func setupHUD() {
        let halfWidthSize = CGSize(width: size.width * 0.8, height: size.height)
        dialogueHUD = DialogueHUD(sceneSize: halfWidthSize)
        // Posiciona na parte de baixo da tela (margem de 48pt)
        dialogueHUD.position = CGPoint(x: size.width/2, y: size.height * 0.001)
        addChild(dialogueHUD)
        applyLocalTextStyling()
        // Remove a caixa preta do HUD: define alpha 0 no background e desliga stroke
        if let box = (dialogueHUD.children.first { $0 is SKShapeNode }) as? SKShapeNode {
            box.fillColor = .clear
            box.strokeColor = .clear
        }
        dialogueHUD.present(animated: true)
    }
    
    private func setupSkipButton() {
//        let label = SKLabelNode(text: "Skip >>>")
        let label = SKLabelNode(text: NSLocalizedString("skip", comment: ""))
        label.fontName = "PixelifySans-Regular"
        label.fontSize = 20
        label.fontColor = .white
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .top
        label.zPosition = 10000
        label.position = CGPoint(x: size.width - 48, y: size.height - 16)
        addChild(label)
        skipLabel = label
        
        // Piscar
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.7)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.7)
        label.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    }
    
    private func setupParagraphs() {
        //TRADUZIR
        // Parágrafos fornecidos pelo usuário
//        let texts: [String] = [
//            "Há muito tempo, as Terras Altas eram o lar dos deuses. Onde a partir do cume, Heliar, deusa do sol, iluminava o mundo.",
//            
//            "Abaixo, os Zarat viviam em paz adorando a luz de sua deusa.",
//            
//            "Mas então, Heliar foi traída por sua irmã, Eclipsa. Que mergulhou o mundo em frio e sombras eternas.",
//            
//            "Porém, antes de sua queda, Heliar lançou um fragmento de sua alma ao longe— uma promessa para quem quer que o encontrasse trazer sua luz de volta.",
//            
//            "O fragmento foi econtrado por uma criança dos Zarat, agora exilados. A jovem Ariah.",
//            
//            "Anos depois, agora guiada pelo poder de sua deusa, Ariah inicia sua campanha na fronteira das Terras Altas… para guiar seu povo de volta ao lar, e cumprir a promessa de sua deusa."
//        ]
//        paragraphs = texts.map { DialogueLine(text: $0, portraitImageName: nil) }
        let texts: [String] = (0...5).map {
            NSLocalizedString("intro.\($0)", comment: "")
        }
        paragraphs = texts.map { DialogueLine(text: $0, portraitImageName: nil) }
    }
    
    private func presentNextParagraph() {
        guard currentIndex < paragraphs.count else {
            endIntro()
            return
        }
        isPresentingParagraph = true
        let line = paragraphs[currentIndex]
        dialogueHUD.configure(line: line)
        applyLocalTextStyling()
        dialogueHUD.present(animated: true)
        
        // Inicia a digitação e, quando terminar, aguarda o tempo de exibição
        dialogueHUD.startTypewriter(charInterval: typeCharInterval) { [weak self] in
            guard let self = self else { return }
            // Mantém o parágrafo visível por 10s
            self.run(.wait(forDuration: self.perParagraphVisibleDuration)) { [weak self] in
                guard let self = self else { return }
                self.dialogueHUD.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.currentIndex += 1
                    self.isPresentingParagraph = false
                    // Pequena pausa entre parágrafos para um ritmo melhor
                    self.run(.wait(forDuration: 0.35)) { [weak self] in
                        self?.dialogueHUD.present(animated: true)
                        self?.presentNextParagraph()
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let skip = skipLabel, skip.contains(location) {
            endIntro()
        }
    }
    
    private func endIntro() {
        guard !hasEnded else { return }
        hasEnded = true
        let fade = SKAction.fadeOut(withDuration: 0.75)
        skipLabel?.run(fade)
        run(fade) { [weak self] in
            self?.onFinished?()
        }
    }
}

