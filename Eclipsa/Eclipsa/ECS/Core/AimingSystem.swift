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
    
    private func setupDragAiming() {
        let path = CGMutablePath()
        path.addArc(center: centerPosition, radius: CGFloat(aimingComponent?.maxRange ?? 0), startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        rangeIndicator?.path = path
        rangeIndicator?.isHidden = false
    }
    func finishAiming(for entity: GKEntity) -> AimingResult? {
        guard let aimingComp = entity.component(ofType: AimingComponent.self),
              aimingComp.isAiming else { return nil }
        
        let result = AimingResult(
            startPoint: aimingComp.startPoint,
            endPoint: aimingComp.endPoint,
        )
        
        aimingComp.isAiming = false
        aimingLine?.isHidden = true
        rangeIndicator?.isHidden = true
        
        return result
    }
    
    func cancelAiming() {
        guard let aimingComp = aimingComponent else { return }
        aimingComp.isAiming = false
        aimingLine?.isHidden = true
        rangeIndicator?.isHidden = true
    }
}

extension AimingSystem: AimingDelegate {
    func handleAim(direction: CGPoint, distance: CGFloat) {
        guard let aimingComp = aimingComponent else {
            return
        }
        aimingComp.isAiming = true
        setupDragAiming()
        let startPoint = centerPosition
        aimingComp.startPoint = startPoint
        
        let realDistance = distance * CGFloat(aimingComp.maxRange) / 50
        
        let clampedDistance = min(realDistance, CGFloat(aimingComp.maxRange))
        let angle = atan2(direction.y, direction.x)

        let endPoint = CGPoint(
            x: startPoint.x + cos(angle) * clampedDistance,
            y: startPoint.y + sin(angle) * clampedDistance
        )

        aimingComp.endPoint = endPoint
        updateAimingLine(from: startPoint, to: endPoint, range: aimingComp.maxRange)
    }
    
    private func updateAimingLine(from start: CGPoint, to end: CGPoint, range: CGFloat) {
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: end)

            aimingLine?.path = path
            aimingLine?.isHidden = false
        }
}
