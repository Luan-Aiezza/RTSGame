//
//  ButtonsSet.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 02/09/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

class ButtonsSet {
    var scene: GameScene
    var followButton: CommandButton!
    var invokeMeleeButton: CommandButton?
    var invokeRangedButton: CommandButton!
    
    init(scene: GameScene) {
        self.scene = scene
//        invokeMeleeButton = CommandButton(position: Position.invokeMeleeButton(size: size), name: "Melee", color: .purple)
        invokeRangedButton = CommandButton(position: Position.invokeRangeButton(size: size), name: "Ranged", color: .orange)
        followButton = CommandButton(position: Position.followButton(size: size), name: "Follow", color: .green)
        
        self.setupButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var size: CGSize {
        scene.size
    }
    
    var camera: SKCameraNode? {
        scene.camera
    }
    
    var entity: UnitEntity {
        scene.controlledEntity
    }
    
    var troops: Set<TroopEntity> {
        scene.troops
    }
    func setupButtons(){
        setupFollowButton()
        setupInvokeRangedButton()
        setupInvokeMeleeButton()
    }
    
    func setupInvokeMeleeButton(){
        guard let invokeMeleeButton = invokeMeleeButton else { return }
        invokeMeleeButton.toggleCommand(value: false)
        invokeMeleeButton.onTouch = { [weak self] in
            guard let self = self else { return }
            self.entity.generator?.generateMelee(troops: self.troops) { troop in
                if let node = troop?.component(ofType: AnimationComponent.self)?.node,
                   let troop = troop{
                    self.scene.addChild(node)
                    SKEntityManager.shared.add(troop)
                }
                
            }
        }
        camera?.addChild(invokeMeleeButton)
    }
    func setupInvokeRangedButton(){
        guard let invokeRangedButton = invokeRangedButton else { return }
        invokeRangedButton.onTouch = { [weak self] in
            guard let self = self else { return }
            self.entity.generator?.generateRanged(troops: self.troops) { troop in
                if let node = troop?.component(ofType: AnimationComponent.self)?.node,
                   let troop = troop{
                    self.scene.addChild(node)
                    SKEntityManager.shared.add(troop)
                }
            }
        }
        
        invokeRangedButton.toggleCommand(value: false)
        camera?.addChild(invokeRangedButton)
    }
    func setupFollowButton(){
        
        followButton.onTouch = { [weak self] in
            self?.scene.troopControlSystem.commandTroopsToFollow()
        }
        followButton.toggleCommand(value: false)
        camera?.addChild(followButton)
    }
    
    
}
