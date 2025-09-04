//
//  ButtonsSet.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 02/09/25.
//

import SpriteKit

class ButtonsSet {
    var scene: GameScene
    var followButton: CommandButton!
    var invokeMeleeButton: CommandButton!
    var invokeRangedButton: CommandButton!
    
    init(scene: GameScene) {
        self.scene = scene
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
    func setupButtons(){
        setupFollowButton()
        setupInvokeRangedButton()
        setupInvokeMeleeButton()
    }
    
    func setupInvokeMeleeButton(){
        invokeMeleeButton = CommandButton(position: Position.invokeMeleeButton(size: size), name: "Melee", color: .purple)
        
        invokeMeleeButton.toggleCommand(value: false)
        camera?.addChild(invokeMeleeButton)
    }
    func setupInvokeRangedButton(){
        invokeRangedButton = CommandButton(position: Position.invokeRangeButton(size: size), name: "Ranged", color: .orange)
        
        invokeRangedButton.toggleCommand(value: false)
        camera?.addChild(invokeRangedButton)
    }
    func setupFollowButton(){
        followButton = CommandButton(position: Position.followButton(size: size), name: "Follow", color: .green)
        
        followButton.onTouch = { [weak self] in
            self?.scene.troopControlSystem.commandTroopsToFollow()
        }
        followButton.toggleCommand(value: false)
        camera?.addChild(followButton)
    }
    
    
}
