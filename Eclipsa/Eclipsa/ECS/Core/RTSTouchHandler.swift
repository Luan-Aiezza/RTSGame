//
//  RTSTouchHandler.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 07/08/25.
//

import GameplayKit
import SpriteKit
import BehindGameKit
import Combine

class RTSTouchHandler {
    weak var scene: GameScene?
    var aimingSystem: AimingSystem
    var selectedEntity: GKEntity?
    
    init(scene: GameScene, aimingSystem: AimingSystem) {
        self.scene = scene
        self.aimingSystem = aimingSystem
    }
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let scene = scene else { return }
        
        let location = touch.location(in: scene)
        if let entity = getEntityAt(location) {
            selectedEntity = entity
            aimingSystem.startAiming(at: location, for: entity)
        }
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let scene = scene,
              let entity = selectedEntity else { return }
        let location = touch.location(in: scene)
        aimingSystem.updateAiming(to: location, for: entity)
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let entity = selectedEntity else { return }
        aimingSystem.cancelAiming(for: entity)
        selectedEntity = nil
    }
    
    private func getEntityAt(_ location: CGPoint) -> GKEntity? {
            
        let touchedNodes = scene?.nodes(at: location) ?? []
        let player = SKEntityManager.shared.getFirstEntity(ofType: UnitEntity.self)
        
        if let node = (player?.moveComponent?.node){
            if touchedNodes.contains(node){
                return player
            }
        }
            
            return nil
        }
}
