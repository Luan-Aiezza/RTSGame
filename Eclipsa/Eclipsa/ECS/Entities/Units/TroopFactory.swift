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
        
        // Define prefixos por time
        let magePrefix: String = (team == .sun) ? "Sun_Mage_" : "Moon_Mage_"
        let soldierPrefix: String = (team == .sun) ? "Soldier_Sun_" : "Soldier_Moon_"
        
        let idleTextures = TextureHandler.makeTexture(name: "\(magePrefix)Idle_", quantity: 4)
        let walkTextures = TextureHandler.makeTexture(name: "\(magePrefix)Walk_", quantity: 4)
        let attackTextures = TextureHandler.makeTexture(name: "\(magePrefix)Casting_", quantity: 12)
        let deathTextures = TextureHandler.makeTexture(name: "\(soldierPrefix)Dead_", quantity: 12)
        let risingTextures = TextureHandler.makeTexture(name: "\(soldierPrefix)Rising_", quantity: 12)
        let spriteSize = CGSize(width: 48, height: 48)
        let maxHealth = 100
        
        let rangedTroop = TroopEntity(team: team, maxHealth: maxHealth, spriteSize: spriteSize, allTroops: allTroops)
        
        guard let animationComponent = rangedTroop.component(ofType: AnimationComponent.self) else { return rangedTroop }
        
        animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
        animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.10, repeatForever: true)
        animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        // Nova animação de invocação
        animationComponent.addAnimation(textures: risingTextures, for: .custom("rising"), timePerFrame: 0.08, repeatForever: false)
        
        let idle = TroopIdleState(troop: rangedTroop)
        let follow = TroopFollowState(troop: rangedTroop)
        let attack = TroopAttackState(troop: rangedTroop)
        let die = TroopDieState(troop: rangedTroop)
        
        let stateMachine = GKStateMachine(states: [idle, follow, attack, die])
        rangedTroop.stateMachineComponent = StateMachineComponent(stateMachine)
        rangedTroop.addComponent(rangedTroop.stateMachineComponent)
        
        // Física, ataque e range
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
        
        // Rodar animação de invocação e depois entrar em Idle
        if let node = rangedTroop.component(ofType: GKSKNodeComponent.self)?.node {
            animationComponent.runAnimation(for: .custom("rising"))
            // Captura a duração da ação atual "animation" no sprite
            let duration = animationComponent.node.action(forKey: "animation")?.duration ?? (0.08 * Double(risingTextures.count))
            node.run(.sequence([
                .wait(forDuration: duration),
                .run { stateMachine.enter(TroopIdleState.self) }
            ]))
        } else {
            stateMachine.enter(TroopIdleState.self)
        }
        
        return rangedTroop
    }
    
    static func makeMelee(team: Team, allTroops: @escaping () -> [TroopEntity]) -> TroopEntity {
        
        // Define prefixos por time
        let soldierPrefix: String = (team == .sun) ? "Sun_Soldier_" : "Moon_Soldier_"
        let risingPrefix: String = (team == .sun) ? "Soldier_Sun_" : "Soldier_Moon_"

        let idleTextures = TextureHandler.makeTexture(name: "\(soldierPrefix)Idle_", quantity: 12)
        let walkTextures = TextureHandler.makeTexture(name: "\(soldierPrefix)Walk_", quantity: 8)
        let attackTextures = TextureHandler.makeTexture(name: "\(soldierPrefix)Attack_", quantity: 3)
        let deathTextures = TextureHandler.makeTexture(name: "\(risingPrefix)Dead_", quantity: 12)
        let risingTextures = TextureHandler.makeTexture(name: "\(risingPrefix)Rising_", quantity: 12)
        let spriteSize = CGSize(width: 48, height: 48)
        let maxHealth = 250
        
        let meleeTroop = TroopEntity(team: team, maxHealth: maxHealth, spriteSize: spriteSize, allTroops: allTroops)
        
        guard let animationComponent = meleeTroop.component(ofType: AnimationComponent.self) else { return meleeTroop }
        
        animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
        animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        animationComponent.addAnimation(textures: attackTextures, for: .attack, timePerFrame: 0.10, repeatForever: true)
        animationComponent.addAnimation(textures: deathTextures, for: .die, timePerFrame: 0.12, repeatForever: false)
        // Nova animação de invocação
        animationComponent.addAnimation(textures: risingTextures, for: .custom("rising"), timePerFrame: 0.08, repeatForever: false)
        
        let idle = TroopIdleState(troop: meleeTroop)
        let follow = TroopFollowState(troop: meleeTroop)
        let attack = TroopAttackState(troop: meleeTroop)
        let die = TroopDieState(troop: meleeTroop)
        
        let stateMachine = GKStateMachine(states: [idle, follow, attack, die])
        meleeTroop.stateMachineComponent = StateMachineComponent(stateMachine)
        meleeTroop.addComponent(meleeTroop.stateMachineComponent)
        meleeTroop.addComponent(MeleeAttackComponent(unit: meleeTroop, damage: 25, cooldown: 1.0))
        
        if let rangeComp = meleeTroop.component(ofType: RangeComponent.self) {
            let meleeRadius: CGFloat = 48   // ⚔️ alcance bem curto
            rangeComp.node.path = CGPath(ellipseIn: CGRect(x: -meleeRadius, y: -meleeRadius,
                                                           width: meleeRadius * 2, height: meleeRadius * 2),
                                         transform: nil)
            rangeComp.node.physicsBody = SKPhysicsBody(circleOfRadius: meleeRadius)
            rangeComp.node.physicsBody?.isDynamic = false
            rangeComp.node.physicsBody?.affectedByGravity = false
            rangeComp.node.physicsBody?.categoryBitMask = PhysicsCategory.range
            rangeComp.node.physicsBody?.collisionBitMask = 0
            rangeComp.node.physicsBody?.contactTestBitMask = PhysicsCategory.troop
        }
        
        // Física e range posicionamento
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
        
        // Rodar animação de invocação e depois entrar em Idle (sobrescreve a entrada imediata)
        if let node = meleeTroop.component(ofType: GKSKNodeComponent.self)?.node {
            animationComponent.runAnimation(for: .custom("rising"))
            let duration = animationComponent.node.action(forKey: "animation")?.duration ?? (0.08 * Double(risingTextures.count))
            node.run(.sequence([
                .wait(forDuration: duration),
                .run { stateMachine.enter(TroopIdleState.self) }
            ]))
        }
        
        return meleeTroop
    }
}


enum TextureHandler {
    static func makeTexture(name: String, quantity: Int) -> [SKTexture] {
        var textures: [SKTexture] = []
        for i in 1...quantity {
            let filename = "\(name)\(i)"
            let tex = SKTexture(imageNamed: filename)
            // heurística: se o tamanho for zero, provavelmente não encontrou o asset
            if tex.size() == .zero {
                print("⚠️ Texture not found -> \(filename). Verifique nome/case no asset catalog.")
            }
            textures.append(tex)
        }
        return textures
    }
}

