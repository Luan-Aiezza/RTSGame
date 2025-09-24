import SpriteKit

extension GameScene {
    // Retém o HUD e controle de diálogo por cena
    private struct DialogueRuntime {
        static var hudKey = "DialogueHUDKey"
        static var runningKey = "DialogueRunningKey"
    }
    
    private var dialogueHUD: DialogueHUDColor? {
        get { return objc_getAssociatedObject(self, &GameScene.DialogueRuntime.hudKey) as? DialogueHUDColor }
        set { objc_setAssociatedObject(self, &GameScene.DialogueRuntime.hudKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var isDialogueRunning: Bool {
        get { (objc_getAssociatedObject(self, &GameScene.DialogueRuntime.runningKey) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &GameScene.DialogueRuntime.runningKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func setupDialogueHUDIfNeeded() {
        guard let camera = self.camera else { return }
        if dialogueHUD == nil {
            let hud = DialogueHUDColor(sceneSize: self.size)
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
        
        // usa DialogueLineColor
        let lines: [DialogueLineColor] = (1...8).map {
            DialogueLineColor(
                text: NSLocalizedString("dialogue.\($0)", comment: ""),
                portraitImageName: nil
            )
        }
        
        runDialogueSequence(lines: lines, hud: hud)
    }
    
    private func runDialogueSequence(lines: [DialogueLineColor], hud: DialogueHUDColor) {
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
                        // 3) aguardar 2s antes do próximo
                        self.run(.wait(forDuration: 2.0)) {
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
