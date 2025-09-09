import SpriteKit

struct DialogueLine {
    let text: String
    let portraitImageName: String? // mantemos por compatibilidade, mas não usamos
}

final class DialogueHUD: SKNode {
    private let textLabel: SKLabelNode
    private let starNode: SKSpriteNode
    
    private var fullText: String = ""
    private var typingTimer: Timer?
    private var currentCharIndex: Int = 0
    private var onTypingCompleted: (() -> Void)?
    
    init(sceneSize: CGSize) {
        // Texto
        textLabel = SKLabelNode(text: "")
        textLabel.fontSize = 16
        textLabel.fontColor = .black
        textLabel.fontName = "CCPixelArcade-Display"
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = sceneSize.width * 0.9
        textLabel.verticalAlignmentMode = .top
        textLabel.horizontalAlignmentMode = .center
        textLabel.zPosition = 10_500
        
        // Estrela animada
        let initialTexture = SKTexture(imageNamed: "Star_Icon_1")
        starNode = SKSpriteNode(texture: initialTexture, size: CGSize(width: 32, height: 32))
        starNode.zPosition = 10_500
        starNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        super.init()
        
        // Posições relativas ao topo da câmera
        let topY = sceneSize.height/3
        textLabel.position = CGPoint(x: 0, y: topY - 10) // texto logo abaixo do topo
        starNode.position = CGPoint(x: 0, y: topY + 18) // estrela acima do texto
        
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
        
        guard !fullText.isEmpty else {
            onCompleted()
            return
        }
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: charInterval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.currentCharIndex < self.fullText.count {
                let idx = self.fullText.index(self.fullText.startIndex, offsetBy: self.currentCharIndex + 1)
                let substring = String(self.fullText[..<idx])
                self.textLabel.text = substring
                self.currentCharIndex += 1
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
}

extension GameScene {
    // Retém o HUD e controle de diálogo por cena
    private struct DialogueRuntime {
        static var hudKey = "DialogueHUDKey"
        static var runningKey = "DialogueRunningKey"
    }
    
    private var dialogueHUD: DialogueHUD? {
        get { return objc_getAssociatedObject(self, &GameScene.DialogueRuntime.hudKey) as? DialogueHUD }
        set { objc_setAssociatedObject(self, &GameScene.DialogueRuntime.hudKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var isDialogueRunning: Bool {
        get { (objc_getAssociatedObject(self, &GameScene.DialogueRuntime.runningKey) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &GameScene.DialogueRuntime.runningKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func setupDialogueHUDIfNeeded() {
        guard let camera = self.camera else { return }
        if dialogueHUD == nil {
            let hud = DialogueHUD(sceneSize: self.size)
            hud.zPosition = 10_500
            hud.position = .zero // centralizado na câmera
            camera.addChild(hud)
            dialogueHUD = hud
        }
    }
    
    // Chamada no sceneDidLoad
    func startDialogue() {
        setupDialogueHUDIfNeeded()
        guard let hud = dialogueHUD, !isDialogueRunning else { return }
        isDialogueRunning = true
        
        let lines: [DialogueLine] = [
            .init(text: "Criança... me escute, nosso poder aumenta, conforme subirmos as terras altas.", portraitImageName: nil),
            .init(text: "Chegou a hora da sua primeira provação, a força que temos agora é apenas um fragmento da meu poder original, porém... Será o suficiente para esse desafio", portraitImageName: nil),
            .init(text: "Mas primeiro você deve se acostumar com frio clima dessas terras, tente dar uma volta utilizando análogico azul.", portraitImageName: nil),
            .init(text: "Ve aquela estrutura dourada? aquele é um santuario solar! a muito erguido para minha adoração, eles serão nossa base por enquanto.", portraitImageName: nil),
            .init(text: "Mas uma base precisa de proteção, tente clicar no botão amarelo no canto esquerdo. Ele lhe permitira invocar os soldados do sol, os antigos guardioes do meu reino, longe de seu auge...", portraitImageName: nil),
            .init(text: "Estes são apenas cascas sem consciencia, precisam receber ordens para combater, primeiro de o comando para eles lhe seguirem no botão verde há direita...", portraitImageName: nil),
            .init(text: "Agora com o análogico vermelho, você pode comandalos para marchar.", portraitImageName: nil),
            .init(text: "Eles são resistentes, porém não tão poderosos, mas sua força aumentara conforme recuperarmos os santuarios.", portraitImageName: nil),
            .init(text: "E falando nisso... eles chegaram, os lunarianos perceberam a nossa presença, se prepare para o combate, maneje suas tropas para defender o santuario.", portraitImageName: nil),
        ]
        
        runDialogueSequence(lines: lines, hud: hud)
    }
    
    private func runDialogueSequence(lines: [DialogueLine], hud: DialogueHUD) {
        guard !lines.isEmpty else {
            isDialogueRunning = false
            return
        }
        
        var index = 0
        
        func showNext() {
            guard index < lines.count else {
                // terminou
                hud.dismiss(animated: true) { [weak self] in
                    self?.isDialogueRunning = false
                }
                return
            }
            
            let line = lines[index]
            hud.configure(line: line)
            hud.present(animated: true)
            
            // 1) digitar texto
            hud.startTypewriter(charInterval: 0.03) { [weak self] in
                guard let self = self else { return }
                // 2) manter 3s após texto completo e desaparecer
                self.run(.wait(forDuration: 5.0)) { [weak self] in
                    guard let self = self else { return }
                    hud.dismiss(animated: true) {
                        // 3) aguardar 5s antes do próximo
                        self.run(.wait(forDuration: 3.0)) {
                            index += 1
                            showNext()
                        }
                    }
                }
            }
        }
        
        showNext()
    }
}
