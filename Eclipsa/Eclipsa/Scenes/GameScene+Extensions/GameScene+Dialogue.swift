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
            
            //FASE 1
            .init(text: "Minha jovem... me escute, vou lhe ensinar o caminho para que você possa subir as terras altas.", portraitImageName: nil),
            
            .init(text: "Primeiramente tente se mover usando o análogico esquerdo e se acostume com o ambiente.", portraitImageName: nil),
            
            .init(text: "Agora precisamos invocar algumas tropas para defender nossa base, experimente clicar no botão amarelo no canto direito", portraitImageName: nil),
            
            .init(text: "Esses são os cavaleiros do sol, não são tão fortes, mas são bem resistentes, experimente comanda-los com o análogico direito", portraitImageName: nil),
            
            .init(text: "Uma vez que recebem uma ordem se quiser que eles lhe sigam novamente, precisara clicar no botão há direita, e eles voltarão a segui-lá.", portraitImageName: nil),
            
            .init(text: "Os cavaleiros da lua estão vindo, defenda o santuário!", portraitImageName: nil),
            
            .init(text: "Você deve encontrar os portais de onde eles vem e destruilos!", portraitImageName: nil),
            
            //FASE 2
            
            .init(text: "A escalada se tornara cada vez mais difil! Para isso precisará de mais poder, defenda o pilar do sol e ele lhe permitira invocar mais tropas ao seu exército.", portraitImageName: nil),
            
            .init(text: "Não deixe que os inimigos destruam seus pilares! ou ficará mais difil criar soldados.", portraitImageName: nil),
            
            
            //FASE 3
            
            .init(text: "Agora que você aprendeu a manejar seus recursos, você pode invocar um novo tipo de tropa, os poderosos magos amarelos.", portraitImageName: nil),
            
            .init(text: "Eles tem muito dano e a vantagem de atacar a distancia, mas são frageis e facilmente derrotados. Por isso faça um bom controle entre cavaleiros e magos.", portraitImageName: nil),
            
            .init(text: "O inimigos está vindo, derrote-o!", portraitImageName: nil),
            
            //FASE 4
            
            
            .init(text: "Eu já lhe ensinei tudo o que podia...", portraitImageName: nil),
            
            .init(text: "Agora cabe a você continuar a escalada e libertar as terras altas do eclipse", portraitImageName: nil),
            
            .init(text: "Que a deusa do sol a proteja, boa sorte em sua jornada...", portraitImageName: nil),
            
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
