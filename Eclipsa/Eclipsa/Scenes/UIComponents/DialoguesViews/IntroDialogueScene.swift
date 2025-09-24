import SpriteKit

// Scene responsável por exibir a introdução com parágrafos e efeito de máquina de escrever
final class IntroDialogueScene: SKScene {
    private var dialogueHUD: DialogueHUD!
    private var paragraphs: [DialogueLine] = []
    private var currentIndex: Int = 0
    private var isPresentingParagraph = false
    private var skipLabel: SKLabelNode?
    private var hasEnded = false
    
    // Novo: imagens da intro
    private var introImages: [SKSpriteNode] = []
    private var currentImage: SKSpriteNode?
    
    // Configurações
    private let perParagraphVisibleDuration: TimeInterval = 4.0
    private let typeCharInterval: TimeInterval = 0.05
    
    var onFinished: (() -> Void)?
    
    override func didMove(to view: SKView) {
        // Inicia a música da intro com fade-in
        AudioManager.shared.fadeInBackgroundMusic(named: "OST_Intro")
        backgroundColor = .black
        isUserInteractionEnabled = true
        setupParagraphs()
        setupImages()
        setupHUD()
        presentNextParagraph()
        setupSkipButton()
    }
    
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
    
    private func setupHUD() {
        let halfWidthSize = CGSize(width: size.width, height: size.height)
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
    
    private func setupSkipButton() {
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
        
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.7)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.7)
        label.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
    }
    
    private func setupParagraphs() {
        let texts: [String] = (0...6).map {
            NSLocalizedString("intro.\($0)", comment: "")
        }
        paragraphs = texts.map { DialogueLine(text: $0, portraitImageName: nil) }
    }
    
    private func setupImages() {
        // Carrega imagens 1 a 6
        introImages = (1...6).map { i in
            let sprite = SKSpriteNode(imageNamed: "Intro_Image_\(i)")
            sprite.position = CGPoint(x: size.width/2, y: size.height * 0.65)
            sprite.setScale(0.2)
            sprite.zPosition = 5000
            sprite.texture?.filteringMode = .nearest
            sprite.alpha = 0
            addChild(sprite)
            return sprite
        }
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
        
        // Troca a imagem correspondente (apenas se existir para esse índice)
        showImage(forIndex: currentIndex)
        
        dialogueHUD.startTypewriter(charInterval: typeCharInterval) { [weak self] in
            guard let self = self else { return }
            self.run(.wait(forDuration: self.perParagraphVisibleDuration)) { [weak self] in
                guard let self = self else { return }
                self.dialogueHUD.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.hideCurrentImage()
                    self.currentIndex += 1
                    self.isPresentingParagraph = false
                    self.run(.wait(forDuration: 0.35)) { [weak self] in
                        self?.presentNextParagraph()
                    }
                }
            }
        }
    }
    
    private func showImage(forIndex index: Int) {
        // Último parágrafo não tem imagem
        guard index < introImages.count else {
            hideCurrentImage()
            return
        }
        hideCurrentImage()
        let sprite = introImages[index]
        currentImage = sprite
        sprite.run(.fadeIn(withDuration: 0.5))
    }
    
    private func hideCurrentImage() {
        currentImage?.run(.fadeOut(withDuration: 0.5))
        currentImage = nil
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
        
        // Fade out da música ~3s
        AudioManager.shared.stopBackgroundMusic()
        
        let fade = SKAction.fadeOut(withDuration: 0.75)
        skipLabel?.run(fade)
        run(fade) { [weak self] in
            self?.onFinished?()
        }
    }
}
