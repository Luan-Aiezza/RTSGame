import SpriteKit

struct DialogueSegment {
    let text: String
    let color: SKColor
}

struct DialogueHighlighter {
    static let colorMap: [String: SKColor] = [
        // 🇬🇧 English
        "BLUE ANALOG.": .systemBlue,
        "YELLOW BUTTON.": .yellow,
        "CROWNS,": .yellow,
        "ALTARS,": .yellow,
        "RED ANALOG": .red,
        "GREEN BUTTON.": .green,
        "SANCTUARY,": .yellow,
        "PORTALS": .purple,
        "BOTÃO LARANJA!": .orange,
        
        // 🇧🇷 Português
        "ANÁLOGICO AZUL.": .systemBlue,
        "BOTÃO AMARELO.": .yellow,
        "COROAS,": .yellow,
        "ALTARES,": .yellow,
        "ANÁLOGICO VERMELHO": .red,
        "BOTÃO VERDE.": .green,
        "SANTUÁRIO,": .yellow,
        "PORTAIS": .systemPurple,
        "ORANGE BUTTON!": .orange
    ]
    
    static func highlightSegments(from text: String) -> [DialogueSegment] {
        var segments: [DialogueSegment] = []
        var remaining = text
        
        while !remaining.isEmpty {
            var match: (keyword: String, range: Range<String.Index>, color: SKColor)? = nil
            
            for (keyword, color) in colorMap {
                if let range = remaining.range(of: keyword) {
                    match = (keyword, range, color)
                    break
                }
            }
            
            if let m = match {
                let before = String(remaining[..<m.range.lowerBound])
                if !before.isEmpty {
                    segments.append(DialogueSegment(text: before, color: .white))
                }
                segments.append(DialogueSegment(text: m.keyword, color: m.color))
                remaining = String(remaining[m.range.upperBound...])
            } else {
                segments.append(DialogueSegment(text: remaining, color: .white))
                break
            }
        }
        return segments
    }
}

struct DialogueLineColor {
    let text: String
    let portraitImageName: String?
}

final class DialogueHUDColor: SKNode {
    private let backgroundBox: SKShapeNode
    private let starNode: SKSpriteNode
    private let textContainer: SKNode
    
    private var fullText: String = ""
    private var segments: [DialogueSegment] = []
    private var displayedText: String = ""
    
    private var typingTimer: Timer?
    private var currentCharIndex: Int = 0
    private var onTypingCompleted: (() -> Void)?
    private var nextAllowedSoundTime: TimeInterval = 0
    
    private let maxWidth: CGFloat
    
    init(sceneSize: CGSize) {
        textContainer = SKNode()
        textContainer.zPosition = 10_510
        
        // Caixa preta com borda amarela
        backgroundBox = SKShapeNode()
        backgroundBox.fillColor = SKColor.black.withAlphaComponent(0.8)
        backgroundBox.strokeColor = SKColor.yellow.withAlphaComponent(0.8)
        backgroundBox.lineWidth = 1
        backgroundBox.zPosition = 10_500
        backgroundBox.isAntialiased = false
        
        // Estrela animada
        let initialTexture = SKTexture(imageNamed: "Star_Icon_1")
        starNode = SKSpriteNode(texture: initialTexture, size: CGSize(width: 32, height: 32))
        starNode.zPosition = 10_520
        starNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        self.maxWidth = sceneSize.width * 0.85
        
        super.init()
        
        let topY = sceneSize.height / 3
        textContainer.position = CGPoint(x: 0, y: topY - 10) // centralizado
        backgroundBox.position = CGPoint(x: 0, y: topY - 5)
        starNode.position = CGPoint(x: 0, y: topY + 25)
        
        addChild(backgroundBox)
        addChild(starNode)
        addChild(textContainer)
        
        alpha = 0.0
        isHidden = true
        
        startStarAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    func configure(line: DialogueLineColor) {
        fullText = line.text
        segments = DialogueHighlighter.highlightSegments(from: fullText)
        displayedText = ""
        currentCharIndex = 0
        textContainer.removeAllChildren()
        updateBoxSize()
    }
    
    private func updateBoxSize() {
        let bounds = textContainer.calculateAccumulatedFrame()
        let padding: CGFloat = 20
        let width = bounds.width + padding
        let height = bounds.height + padding
        
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
        displayedText = ""
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
                self.displayedText = String(self.fullText[..<idx])
                self.renderDisplayedText()
                self.currentCharIndex += 1
                self.updateBoxSize()
                
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
    
    private func renderDisplayedText() {
        textContainer.removeAllChildren()
        
        let fontSize: CGFloat = 16
        let fontName = "PixelifySans-Regular"
        let lineHeight: CGFloat = fontSize + 6
        
        var remaining = displayedText
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var currentLineNodes: [SKLabelNode] = []
        
        for segment in segments {
            guard !remaining.isEmpty else { break }
            let segmentText = segment.text
            let visible = segmentText.commonPrefix(with: remaining)
            remaining = String(remaining.dropFirst(visible.count))
            
            guard !visible.isEmpty else { continue }
            
            // Criar label do segmento visível
            let label = SKLabelNode(text: visible)
            label.fontName = fontName
            label.fontSize = fontSize
            label.fontColor = segment.color
            label.verticalAlignmentMode = .top
            label.horizontalAlignmentMode = .left
            
            // --- 🔥 VERIFICA SE CABE NA LINHA ---
            let futureWidth = xOffset + label.frame.width
            if futureWidth > maxWidth, xOffset > 0 {
                // Centraliza linha anterior antes de quebrar
                centerLine(lineNodes: currentLineNodes, totalWidth: xOffset)
                currentLineNodes.removeAll()
                
                // Quebra de linha
                xOffset = 0
                yOffset += lineHeight
            }
            
            // Posiciona label na linha atual
            label.position = CGPoint(x: xOffset, y: -yOffset)
            textContainer.addChild(label)
            currentLineNodes.append(label)
            
            xOffset += label.frame.width
        }
        
        // Centraliza última linha
        if !currentLineNodes.isEmpty {
            centerLine(lineNodes: currentLineNodes, totalWidth: xOffset)
        }
    }

    
    private func centerLine(lineNodes: [SKLabelNode], totalWidth: CGFloat) {
        let offset = -totalWidth / 2
        for node in lineNodes {
            node.position.x += offset
        }
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
}
