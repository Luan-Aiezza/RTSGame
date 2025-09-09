// GameScene+Input.swift
import SpriteKit
import BehindGameKit
import GameplayKit

extension GameScene {
    
    private func overlayIsActive() -> Bool {
        return camera?.childNode(withName: "DefeatOverlay") != nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Se a overlay de derrota está ativa, só processa overlay e bloqueia o resto
        if overlayIsActive() {
            if let touch = touches.first, let camera {
                let locationInCamera = touch.location(in: camera)
                _ = tryHandleOverlayTouch(locationInCamera) // tenta clicar no Restart
            }
            return
        }
        
        // Sem overlay: se houver câmera, também priorizamos clique em overlay (no caso de corrida de estado)
        if let touch = touches.first, let camera {
            let locationInCamera = touch.location(in: camera)
            if tryHandleOverlayTouch(locationInCamera) {
                return // se foi clique no overlay, não processa input normal
            }
        }
        
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        // Converter o ponto de toque da coordenada da câmera para a cena global (caso necessário para outras lógicas)
        _ = camera.convert(location, to: self)
        releaseButton.handleTouch(location)
        buttons.followButton.handleTouch(location)
        buttons.invokeRangedButton.handleTouch(location)
        buttons.invokeMeleeButton.handleTouch(location)
        if location.x <= 0 {
            gameController?.setAnalogVisible(value: true)
            gameController?.changePosition(location)
            gameController?.touchBegan(touches, with: event)
        } else if location.x > 0 && (aimingSystem?.aimingComponent?.isAiming ?? false) {
            commandController?.setAnalogVisible(value: true)
            commandController?.touchBegan(touches, with: event)
            cancelButton.toggleCommand(value: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Bloqueia toda interação do jogo quando overlay está ativa
        if overlayIsActive() {
            return
        }
        
        guard let camera, let location = touches.first?.location(in: camera) else { return }
        if location.x <= 0 {
            gameController?.touchMoved(touches, with: event)
        } else {
            commandController?.touchMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Bloqueia toda interação do jogo quando overlay está ativa, exceto tentar o clique no Restart
        if overlayIsActive() {
            if let touch = touches.first, let camera {
                let locationInCamera = touch.location(in: camera)
                _ = tryHandleOverlayTouch(locationInCamera)
            }
            return
        }
        
        guard let camera,
              let location = touches.first?.location(in: camera) else { return }
        if location.x <= 0 {
            gameController?.touchesEnded(touches, with: event)
            gameController?.setAnalogVisible(value: false, withDuration: 0.6)
        } else if location.x > 0 {
            cancelButton.handleTouch(location)
            
            aimingSystem?.finishAiming { [weak self] result in
                for troop in self?.troops ?? [] {
                    guard
                        let troopTeam = troop.component(ofType: TeamComponent.self)?.team,
                        let playerTeam = self?.controlledEntity.component(ofType: TeamComponent.self)?.team,
                        troopTeam == playerTeam
                    else { continue }

                    // 🔑 Só deixa receber comando manual se já estava em follow do player
                    if let behavior = troop.component(ofType: TroopBehaviorComponent.self),
                       (behavior.target as? UnitEntity) === self?.controlledEntity {
                        
                        behavior.manualTargetPoint = result.endPoint
                        behavior.setTarget(nil) // sem inimigo → vá pro ponto
                    }
                }
                self?.cancelButton.toggleCommand(value: true)
            }
            commandController?.touchesEnded(touches, with: event)
            commandController?.setAnalogVisible(value: false, withDuration: 0.6)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Bloqueia toda interação do jogo quando overlay está ativa
        if overlayIsActive() {
            return
        }
        gameController?.touchesCancelled(touches, with: event)
        gameController?.setAnalogVisible(value: false, withDuration: 0.6)
        commandController?.touchesEnded(touches, with: event)
        commandController?.setAnalogVisible(value: false, withDuration: 0.6)
    }
}

