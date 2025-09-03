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
    }
    
    func setupInvokeMeleeButton(){}
    func setupInvokeRangedButton(){}
    func setupFollowButton(){
        followButton = CommandButton(position: Position.followButton(size: size), name: "Follow", color: .green)
        
        followButton.onTouch = { [weak self] in
            self?.scene.troopControlSystem.commandTroopsToFollow()
        }
        followButton.toggleCommand(value: false)
        camera?.addChild(followButton)
    }
    
    
}
