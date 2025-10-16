// GameScene+Input.swift
import SpriteKit
import BehindGameKit
import GameplayKit

extension GameScene {
    
    private func overlayIsActive() -> Bool {
        return camera?.childNode(withName: "DefeatOverlay") != nil || camera?.childNode(withName: "WinOverlay") != nil
    }
    
    // 🔑 Variáveis auxiliares para distinguir tap de arrasto
    private var minimumDragDistance: CGFloat { 20 }
    private var touchStartLocation: CGPoint? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.startLocation) as? CGPoint }
        set { objc_setAssociatedObject(self, &AssociatedKeys.startLocation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private struct AssociatedKeys {
        static var startLocation = "GameScene_TouchStartLocation"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPaused { return }
        if overlayIsActive() {
            if let touch = touches.first, let camera {
                let locationInCamera = touch.location(in: camera)
                if tryHandleWinOverlayTouch(locationInCamera) { return }
                if tryHandleOverlayTouch(locationInCamera) { return }
            }
            return
        }
        
        if let touch = touches.first, let camera {
            let locationInCamera = touch.location(in: camera)
            if tryHandleWinOverlayTouch(locationInCamera) { return }
            if tryHandleOverlayTouch(locationInCamera) { return }
            
            // guarda início do toque
            touchStartLocation = locationInCamera
        }
        
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        _ = camera.convert(location, to: self)
        
        releaseButton.handleTouch(location)
        buttons.followButton?.handleTouch(location)
        buttons.invokeRangedButton?.handleTouch(location)
        buttons.invokeMeleeButton?.handleTouch(location)
        
        if let commandController = commandController, commandController.onTouchBegan == nil {
            commandController.onTouchBegan = { [weak self] in
                guard let self = self else { return }
                self.troopControlSystem?.commandTroopsToFollow()
            }
        }
        
        if location.x <= 0 {
            gameController?.touchBegan(touches, with: event)
        } else if location.x > 0 && (aimingSystem?.aimingComponent?.isAiming ?? false) {
            commandController?.setAnalogVisible(value: true)
            commandController?.touchBegan(touches, with: event)
            cancelButton.toggleCommand(value: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if overlayIsActive() { return }
        if isPaused { return }
        
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        if location.x <= 0 {
            gameController?.touchMoved(touches, with: event)
        } else {
            commandController?.touchMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if isPaused { return }
        if overlayIsActive() {
            if let touch = touches.first, let camera {
                let locationInCamera = touch.location(in: camera)
                if tryHandleWinOverlayTouch(locationInCamera) { return }
                _ = tryHandleOverlayTouch(locationInCamera)
            }
            return
        }
        
        guard let camera,
              let location = touches.first?.location(in: camera) else { return }
        
        if location.x <= 0 {
            gameController?.touchesEnded(touches, with: event)
        } else if location.x > 0 {
            cancelButton.handleTouch(location)
            
            let didMove: Bool = {
                if let start = touchStartLocation {
                    return start.distance(to: location) > minimumDragDistance
                }
                return false
            }()
            
            if didMove {
                // 👉 Só dispara comando manual se foi arrasto real
                aimingSystem?.finishAiming { [weak self] result in
                    
                    // ✅ Som aleatório
                    DispatchQueue.main.async {
                        AudioManager.shared.playVoice(named: "Voice_\(Int.random(in: 1...5))")
                    }

                    // ✅ Efeito visual
                    self!.showFollowEffect(at: result.endPoint)
                    
                    for troop in self?.troops ?? [] {
                        guard
                            let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
                            let playerTeam = self?.controlledEntity?.component(ofType: TeamComponent.self)?.team,
                            troopTeam == playerTeam
                        else { continue }

                        if let behavior = troop.component(ofType: TroopBehaviorComponent.self),
                           (behavior.getCurrentEnemyTarget()) === self?.controlledEntity {
                            behavior.setManualTargetPoint(result.endPoint)
                            behavior.setTarget(nil)
                        }
                    }
                    
                    self?.cancelButton.toggleCommand(value: true)
                }
            } else {
                // 👉 Toque simples: ignora, tropas continuam seguindo
                aimingSystem?.cancelAiming()
                cancelButton.toggleCommand(value: true)
            }
            
            commandController?.touchesEnded(touches, with: event)
            commandController?.setAnalogVisible(value: false, withDuration: 0.3)
        }
        
        // limpa início
        touchStartLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if overlayIsActive() { return }
        gameController?.touchesCancelled(touches, with: event)
        commandController?.touchesEnded(touches, with: event)
        commandController?.setAnalogVisible(value: false, withDuration: 0.3)
        touchStartLocation = nil
    }
    
    private func showFollowEffect(at position: CGPoint) {
        // Carrega a sequência fixa de frames Follow_Effect_1 ... Follow_Effect_10
        let textures = (1...10).compactMap { SKTexture(imageNamed: "Follow_Effect_\($0)") }
        guard !textures.isEmpty else { return }

        // Cria o sprite inicial com o primeiro frame
        let sprite = SKSpriteNode(texture: textures.first)
        sprite.position = position
        sprite.zPosition = 1000
        sprite.texture?.filteringMode = .nearest
        sprite.alpha = 0.8
        sprite.setScale(0.5)
        
        addChild(sprite)

        // Cria a animação
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()

        // Executa tudo em sequência
        sprite.run(.sequence([animation, fadeOut, remove]))
    }

    
    
}

// Utilitário
private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
