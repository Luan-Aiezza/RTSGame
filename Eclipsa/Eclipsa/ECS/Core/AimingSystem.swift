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
    
    func startAiming(at point: CGPoint, for entity: GKEntity) {
        guard let aimingComp = entity.component(ofType: AimingComponent.self) else {
            print("Erro: Entidade não tem AimingComponent")
            return
        }
        
        aimingComp.isAiming = true
        aimingComp.startPoint = point
        aimingComp.endPoint = point
        
        setupDragAiming(at: point, range: aimingComp.maxRange)
    }
    
    private func setupDragAiming(at point: CGPoint, range: Float) {
        print("Configurando drag aiming - range: \(range)")
        
        // Círculo de alcance para movimento
        let path = CGMutablePath()
        path.addArc(center: point, radius: CGFloat(range), startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        rangeIndicator?.path = path
        rangeIndicator?.isHidden = false
        
        print("Círculo de alcance mostrado")
    }
    
    func updateAiming(to point: CGPoint, for entity: GKEntity) {
        guard let aimingComp = entity.component(ofType: AimingComponent.self),
              aimingComp.isAiming else {
            print("Erro: Componente não está em modo aiming")
            return
        }
        
        aimingComp.endPoint = point
        updateDragAiming(from: aimingComp.startPoint, to: point, range: aimingComp.maxRange)
    }
    
    private func updateDragAiming(from start: CGPoint, to current: CGPoint, range: Float) {
        let distance = hypot(current.x - start.x, current.y - start.y)
        let clampedDistance = min(distance, CGFloat(range))
        
        // Calcular ponto final limitado pelo alcance
        let angle = atan2(current.y - start.y, current.x - start.x)
        let endPoint = CGPoint(
            x: start.x + cos(angle) * clampedDistance,
            y: start.y + sin(angle) * clampedDistance
        )
        
        // Atualizar linha
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: endPoint)
        
        aimingLine?.path = path
        aimingLine?.isHidden = false
        
        // Atualizar cor baseada na distância
        let normalizedDistance = Float(distance) / range
        if normalizedDistance > 1.0 {
            aimingLine?.strokeColor = .red
        } else {
            aimingLine?.strokeColor = .cyan
        }
        
        print("Linha atualizada: \(start) -> \(endPoint), distância: \(distance)")
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
