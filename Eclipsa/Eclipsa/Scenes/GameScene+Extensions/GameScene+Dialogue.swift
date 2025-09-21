import SpriteKit

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
            //TRADUZIR
            //FASE 1
            .init(text: "Ariah... consegue me ouvir? quem vos fala é Heliar. Vou lhe ensinar o caminho para que você possa subir estas terras.", portraitImageName: nil),
            
                .init(text: "Primeiramente tente se mover usando o ANÁLOGICO ESQUERDO e se acostume com o ambiente.", portraitImageName: nil),
            
                .init(text: "Agora precisamos invocar algumas tropas para defender sua base, experimente clicar no BOTÃO no canto INFERIOR DIREITO", portraitImageName: nil),
            
                .init(text: "As tropas custam recursos, que são gerados a partir dos altares solares, defenda-os a todo custo.", portraitImageName: nil),
            
                .init(text: "Posicione suas tropas com o ANÁLOGICO DIREITO, ou chame-as para perto o botão abaixo.", portraitImageName: nil),
            
                .init(text: "Os cavaleiros da lua estão vindo! não deixe que destruam seus altares, ou ficará mais difil criar soldados.", portraitImageName: nil),
            
                .init(text: "Eles sempre virão atrás do Santuário, se perde-lô é o fim!", portraitImageName: nil),
            
                .init(text: "Você deve encontrar os portais inimigos e destruilos, é o unico jeito de vencer!", portraitImageName: nil),
            
                .init(text: "Isso é tudo por enquanto... agora é com você!", portraitImageName: nil),
            
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
