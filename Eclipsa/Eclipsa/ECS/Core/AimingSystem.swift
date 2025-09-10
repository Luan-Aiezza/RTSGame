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
    
    private var lastAimDirection: CGPoint = .zero
    private var lastAimDistance: CGFloat = 0.0
    
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
        if let node = player?.component(ofType: GKSKNodeComponent.self)?.node {
            return node.position
        }
        return .zero
    }
    
    func startAiming() {
        guard let component = aimingComponent else {return}
        component.isAiming = true
        setupDragAiming()
    }
    
    private func setupDragAiming() {
        let path = CGMutablePath()
        path.addArc(center: centerPosition, radius: CGFloat(aimingComponent?.maxRange ?? 0), startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        rangeIndicator?.path = path
        rangeIndicator?.isHidden = false
    }
    func finishAiming(completion: ((_ result: AimingResult) -> Void)) {
        guard let aimingComp = aimingComponent,
              aimingComp.isAiming else { return }
        let result = AimingResult(startPoint: aimingComp.startPoint, endPoint: aimingComp.endPoint)
        aimingComp.isAiming = false
        aimingLine?.isHidden = true
        rangeIndicator?.isHidden = true
        completion(result)
    }
    
    func cancelAiming() {
        guard let aimingComp = aimingComponent else { return }
        print("cancelado")
        aimingComp.isAiming = false
        aimingLine?.isHidden = true
        rangeIndicator?.isHidden = true
    }
    
    func updateRangeIndicatorPosition() {
        guard aimingComponent != nil else { return }
        let path = CGMutablePath()
        path.addArc(
            center: centerPosition, // Usa a posição atual do jogador
            radius: CGFloat(aimingComponent?.maxRange ?? 0),
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        
        rangeIndicator?.path = path
    }
}

extension AimingSystem: AimingDelegate {
    func handleAim(direction: CGPoint, distance: CGFloat) {
        guard let aimingComp = aimingComponent,
        aimingComp.isAiming else {return}
        let startPoint = centerPosition
        aimingComp.startPoint = startPoint
        
        let realDistance = distance * CGFloat(aimingComp.maxRange) / 50
        
        let clampedDistance = min(realDistance, CGFloat(aimingComp.maxRange))
        let angle = atan2(direction.y, direction.x)
        let endPoint = CGPoint(
            x: startPoint.x + cos(angle) * clampedDistance,
            y: startPoint.y + sin(angle) * clampedDistance
        )
        lastAimDirection = direction
        lastAimDistance = clampedDistance
        
        aimingComp.endPoint = endPoint
        updateAimingLine(to: endPoint)
    }
    
    func updateAimingLine(to end: CGPoint) {
            let path = CGMutablePath()
            path.move(to: centerPosition)
            path.addLine(to: end)
        
        aimingLine?.path = path
        aimingLine?.isHidden = false
        updateRangeIndicatorPosition()
        }
    
    func updateDynamicAiming() {
        guard let aimingComp = aimingComponent, aimingComp.isAiming else { return }
        if lastAimDirection != .zero {
            let currentStartPoint = centerPosition
            let angle = atan2(lastAimDirection.y, lastAimDirection.x)
            let clampedDistance = min(lastAimDistance, CGFloat(aimingComp.maxRange))
            
            let newEndPoint = CGPoint(
                x: currentStartPoint.x + cos(angle) * clampedDistance,
                y: currentStartPoint.y + sin(angle) * clampedDistance
            )
            aimingComp.startPoint = currentStartPoint
            aimingComp.endPoint = newEndPoint
            updateAimingLine(to: newEndPoint)
            updateRangeIndicatorPosition()
        }
    }
}
