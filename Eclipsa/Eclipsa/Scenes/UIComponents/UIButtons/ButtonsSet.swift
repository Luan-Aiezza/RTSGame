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
    var followButton: CommandButton?
    var invokeMeleeButton: CommandButton?
    var invokeRangedButton: CommandButton?
    
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
    
    var entity: UnitEntity? {
        scene.controlledEntity
    }
    
    var troops: Set<TroopEntity> {
        scene.troops
    }
    private func setupButtons(){
        //setupFollowButtonUI()
        setupInvokeRangedButtonUI()
        setupInvokeMeleeButtonUI()
    }
    
    private func setupInvokeMeleeButtonUI(){
        invokeMeleeButton = CommandButton(position: Position.invokeMeleeButton(size: size), name: "Melee", color: .orange)
        invokeMeleeButton?.changeLabelToImage(with: "Knight_Invoke_Icon")
        invokeMeleeButton?.changeButtonColors(buttonColor: Colors.meleeButtonFillColor, strokeColor: .black)
        setupInvokeMeleeButton()
    }
    
    private func setupInvokeMeleeButton(){
        guard let invokeMeleeButton = invokeMeleeButton else { return }
        invokeMeleeButton.toggleCommand(value: false)
        invokeMeleeButton.onTouch = { [weak self] in
            guard let self = self else { return }
            if ResourceHandler.shared.getStoredResources() >= TroopCost.meleeCost{
                self.entity?.generator?.generateMelee(troops: self.troops) { troop in
                    if let node = troop?.component(ofType: AnimationComponent.self)?.node,
                       let troop = troop{
                        self.scene.addChild(node)
                        SKEntityManager.shared.add(troop)
                        ResourceHandler.shared.spendResources(TroopCost.meleeCost)
                        AchievementManager.shared.recordMeleeCreation()
                    }
                    
                }
                AudioManager.shared.playSound(named: "Invoke_Effect")
            }
        }
        camera?.addChild(invokeMeleeButton)
    }
    
    private func setupInvokeRangedButtonUI(){
        invokeRangedButton = CommandButton(position: Position.invokeRangeButton(size: size), name: "Ranged", color: .orange)
        invokeRangedButton?.changeLabelToImage(with: "Mage_Invoke_Icon")
        invokeRangedButton?.changeButtonColors(buttonColor: Colors.rangedButtonFillColor, strokeColor: .black)
        setupInvokeRangedButton()
    }
    
    private func setupInvokeRangedButton(){
        guard let invokeRangedButton = invokeRangedButton else { return }
        invokeRangedButton.onTouch = { [weak self] in
            guard let self = self else { return }
            if ResourceHandler.shared.getStoredResources() >= TroopCost.rangedCost {
                self.entity?.generator?.generateRanged(troops: self.troops) { troop in
                    if let node = troop?.component(ofType: AnimationComponent.self)?.node,
                       let troop = troop{
                        self.scene.addChild(node)
                        SKEntityManager.shared.add(troop)
                        ResourceHandler.shared.spendResources(TroopCost.rangedCost)
                        AchievementManager.shared.recordRangedCreation()
                    }
                }
                AudioManager.shared.playSound(named: "Invoke_Effect")
            }
        }
        invokeRangedButton.toggleCommand(value: false)
        camera?.addChild(invokeRangedButton)
    }
    
    private func setupFollowButtonUI(){
        followButton = CommandButton(position: Position.followButton(size: size), name: "", color: .green)
        followButton?.changeLabelToImage(with: "Follow_Icon")
        followButton?.changeButtonColors(buttonColor: Colors.followButtonFillColor, strokeColor: Colors.followButtonStrokeColor)
        
        setupFollowButton()
    }
    
    private func setupFollowButton(){
        guard let followButton = followButton else { return }
        followButton.onTouch = { [weak self] in
            guard let self = self else { return }
            self.scene.troopControlSystem.commandTroopsToFollow()
            //self.scene.playFollowEffectAtPlayer()

        }
        followButton.toggleCommand(value: false)
        camera?.addChild(followButton)
    }
    
    
}
