//
//  AimingSsystem.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 07/08/25.
//

import GameplayKit
import SpriteKit
import BehindGameKit
import Combine

class AimingSystem: GKComponentSystem<AimingComponent> {
    weak var scene: SKScene?
    var player: UnitEntity?
    private var aimingLine: SKShapeNode?
    private var rangeIndicator: SKShapeNode?
    
    init(scene: SKScene) {
        self.scene = scene
        super.init(componentClass: AimingComponent.self)
        setupAimingVisuals()
    }
    
    private func setupAimingVisuals() {
        
        aimingLine = SKShapeNode()
        aimingLine?.strokeColor = .cyan
        aimingLine?.lineWidth = 4.0
        aimingLine?.alpha = 0.9
        aimingLine?.isHidden = true
        aimingLine?.zPosition = 100
        scene?.addChild(aimingLine!)
        
        rangeIndicator = SKShapeNode()
        rangeIndicator?.strokeColor = .white
        rangeIndicator?.fillColor = .clear
        rangeIndicator?.lineWidth = 2.0
        rangeIndicator?.alpha = 0.4
        rangeIndicator?.isHidden = true
        rangeIndicator?.zPosition = 99
        scene?.addChild(rangeIndicator!)
    }
    
    var aimingComponent: AimingComponent? {
        return player?.component(ofType: AimingComponent.self)
    }
    
    var centerPosition: CGPoint {
        guard let position = player?.moveComponent?.node?.position else { return .zero }
        return position
    }
    
    func startAiming() {
        guard let aimingComp = aimingComponent
        else {
            print("Erro: Entidade não tem AimingComponent")
            return
        }
        
        aimingComp.isAiming = true
        aimingComp.startPoint = centerPosition
        aimingComp.endPoint = centerPosition
        
        setupDragAiming()
    }
    
    private func setupDragAiming() {
        let path = CGMutablePath()
        path.addArc(center: centerPosition, radius: CGFloat(aimingComponent?.maxRange ?? 0), startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        rangeIndicator?.path = path
        rangeIndicator?.isHidden = false
    }
    
    func updateAiming(to point: CGPoint, for entity: GKEntity) {
        guard let aimingComp = aimingComponent else { return }
        
        aimingComp.startPoint = centerPosition
        aimingComp.endPoint = point
        updateDragAiming(from: aimingComp.startPoint, to: point, range: aimingComp.maxRange)
    }
    
    private func updateDragAiming(from start: CGPoint, to current: CGPoint, range: Float) {
        let distance = hypot(current.x - start.x, current.y - start.y)
        let clampedDistance = min(distance, CGFloat(range))
        
        let angle = atan2(current.y - start.y, current.x - start.x)
        let endPoint = CGPoint(
            x: start.x + cos(angle) * clampedDistance,
            y: start.y + sin(angle) * clampedDistance
        )
        
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: endPoint)
        
        aimingLine?.path = path
        aimingLine?.isHidden = false
        
        let normalizedDistance = Float(distance) / range
        if normalizedDistance > 1.0 {
            aimingLine?.strokeColor = .red
        } else {
            aimingLine?.strokeColor = .cyan
        }
    }
    
    func finishAiming(for entity: GKEntity) -> AimingResult? {
        guard let aimingComp = entity.component(ofType: AimingComponent.self),
              aimingComp.isAiming else { return nil }
        
        print("Finalizando aiming")
        
        let result = AimingResult(
            startPoint: aimingComp.startPoint,
            endPoint: aimingComp.endPoint,
        )
        
        // Reset
        aimingComp.isAiming = false
        aimingLine?.isHidden = true
        rangeIndicator?.isHidden = true
        
        return result
    }
    
    func cancelAiming(for entity: GKEntity) {
        guard let aimingComp = entity.component(ofType: AimingComponent.self) else { return }
        
        print("Cancelando aiming")
        
        aimingComp.isAiming = false
        aimingLine?.isHidden = true
        rangeIndicator?.isHidden = true
    }
}

extension AimingSystem: AimingDelegate {
    func handleAim(direction: CGPoint, distance: CGFloat) {
        guard let aimingComp = aimingComponent, aimingComp.isAiming else {
            return
        }
        // 1. Obter o ponto de início (centro do jogador)
        let startPoint = centerPosition
        
        // 2. Calcular o ponto final da mira.
        // A distância máxima da mira é o maxRange do componente.
        // A distância do pad (distance) precisa ser proporcional a esse maxRange.
        // Como o pad já retorna a distância, vamos usá-la diretamente.
        // O `min` garante que a distância não ultrapasse o alcance máximo.
        let clampedDistance = min(distance, CGFloat(aimingComp.maxRange))
        
        let endPoint = CGPoint(
            x: startPoint.x + direction.x * clampedDistance,
            y: startPoint.y + direction.y * clampedDistance
        )
        
        // 3. Atualizar o componente de mira com os novos pontos
        aimingComp.startPoint = startPoint
        aimingComp.endPoint = endPoint
        
        // 4. Chamar a função que desenha a mira na tela
        updateAimingLine(from: startPoint, to: endPoint, range: aimingComp.maxRange)
    }
    
    private func updateAimingLine(from start: CGPoint, to end: CGPoint, range: Float) {
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: end)

            aimingLine?.path = path
            aimingLine?.isHidden = false

            // Lógica de mudança de cor se a mira ultrapassa o range (opcional)
            let distance = start.distance(to: end)
            if distance > CGFloat(range) {
                aimingLine?.strokeColor = .red
            } else {
                aimingLine?.strokeColor = .cyan
            }
        }
}
