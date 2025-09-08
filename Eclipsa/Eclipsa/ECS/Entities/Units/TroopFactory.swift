//
//  TroopFactory.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 03/09/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

enum TroopFactory{
   static func makeRanged(team: Team, allTroops: @escaping () -> [TroopEntity]) -> TroopEntity {
        
        let idleTextures = TextureHandler.makeTexture(name: "Sun_Mage_Idle_", quantity: 4)
        let walkTextures = TextureHandler.makeTexture(name: "Sun_Mage_Walk_", quantity: 4)
        let attackTextures = TextureHandler.makeTexture(name: "Sun_Mage_Casting_", quantity: 12)
        let deathTextures = TextureHandler.makeTexture(name: "Soldier_Sun_Dead_", quantity: 12)
        let spriteSize = CGSize(width: 48, height: 48)
        let maxHealth = 50
        
        let rangedTroop = TroopEntity(team: team, maxHealth: maxHealth, spriteSize: spriteSize, allTroops: allTroops)
        
        guard let animationComponent = rangedTroop.component(ofType: AnimationComponent.self) else { return rangedTroop }
        
        animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
        animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.10, repeatForever: true)
        animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        
        let idle = TroopIdleState(troop: rangedTroop)
        let follow = TroopFollowState(troop: rangedTroop)
        let attack = TroopAttackState(troop: rangedTroop)
        let die = TroopDieState(troop: rangedTroop)
        
        let stateMachine = GKStateMachine(states: [idle, follow, attack, die])
        rangedTroop.stateMachineComponent = StateMachineComponent(stateMachine)
        rangedTroop.addComponent(rangedTroop.stateMachineComponent)
        
        stateMachine.enter(TroopIdleState.self)
        
       rangedTroop.addComponent(AttackComponent(unit: rangedTroop, damage: 3, cooldown: 2.0))
       PhysicsSystem.setupTroopPhysics(for: rangedTroop)
       
       if let rangeComp = rangedTroop.component(ofType: RangeComponent.self),
          let nodeComp = rangedTroop.component(ofType: GKSKNodeComponent.self) {
           let scene = nodeComp.node.scene
           let positionInScene = nodeComp.node.position
           rangeComp.node.position = positionInScene
           if rangeComp.node.parent !== scene {
               scene?.addChild(rangeComp.node)
           }
       }
        
        return rangedTroop
    }
    
    static func makeMelee(team: Team, allTroops: @escaping () -> [TroopEntity]) -> TroopEntity {
        
        let idleTextures = TextureHandler.makeTexture(name: "Sun_Soldier_Idle_", quantity: 12)
        print(idleTextures[0])
        let walkTextures = TextureHandler.makeTexture(name: "Sun_Soldier_Walk_", quantity: 8)
        let attackTextures = TextureHandler.makeTexture(name: "Sun_Soldier_Attack_", quantity: 3)
        let deathTextures = TextureHandler.makeTexture(name: "Sun_Soldier_Death_", quantity: 6)
        let spriteSize = CGSize(width: 32, height: 32)
        let maxHealth = 150
        
        let meleeTroop = TroopEntity(team: team, maxHealth: maxHealth, spriteSize: spriteSize, allTroops: allTroops)
        
        guard let animationComponent = meleeTroop.component(ofType: AnimationComponent.self) else { return meleeTroop }
        
        animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
        animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.10, repeatForever: true)
        animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        
        let idle = TroopIdleState(troop: meleeTroop)
        let follow = TroopFollowState(troop: meleeTroop)
        let attack = TroopAttackState(troop: meleeTroop)
        let die = TroopDieState(troop: meleeTroop)
        
        let stateMachine = GKStateMachine(states: [idle, follow, attack, die])
        meleeTroop.stateMachineComponent = StateMachineComponent(stateMachine)
        meleeTroop.addComponent(meleeTroop.stateMachineComponent)
        meleeTroop.addComponent(MeleeAttackComponent(attacker: meleeTroop, damage: 25, cooldown: 1.0))
        
        if let rangeComp = meleeTroop.component(ofType: RangeComponent.self) {
            rangeComp.node.path = CGPath(ellipseIn: CGRect(x: -16, y: -16, width: 32, height: 32), transform: nil)
            rangeComp.node.physicsBody = SKPhysicsBody(circleOfRadius: 16) // range bem menor
            rangeComp.node.physicsBody?.isDynamic = false
            rangeComp.node.physicsBody?.affectedByGravity = false
            rangeComp.node.physicsBody?.categoryBitMask = PhysicsCategory.range
            rangeComp.node.physicsBody?.collisionBitMask = 0
            rangeComp.node.physicsBody?.contactTestBitMask = PhysicsCategory.troop
        }
        stateMachine.enter(TroopIdleState.self)
        
        PhysicsSystem.setupTroopPhysics(for: meleeTroop)
        
        if let rangeComp = meleeTroop.component(ofType: RangeComponent.self),
           let nodeComp = meleeTroop.component(ofType: GKSKNodeComponent.self) {
            let scene = nodeComp.node.scene
            let positionInScene = nodeComp.node.position
            rangeComp.node.position = positionInScene
            if rangeComp.node.parent !== scene {
                scene?.addChild(rangeComp.node)
            }
        }
        
        return meleeTroop
    }
}


enum TextureHandler{
    static func makeTexture(name: String, quantity: Int) -> [SKTexture]{
        let textures = (1...quantity).map{ SKTexture(imageNamed: "\(name)\($0)")}
        
        return textures
    }
    
}
