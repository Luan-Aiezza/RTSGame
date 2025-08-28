//
//  Proje.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 27/08/25.
//

import SpriteKit
import GameplayKit
import BehindGameKit

public class ProjectileEntity: GKEntity {
    private let damage: Int
    private weak var target: TroopEntity?
    private let speed: CGFloat = 180.0 // px/segundo
    
    private var sprite: SKSpriteNode
    private var animationComponent: AnimationComponent
    
    init(from origin: CGPoint, target: TroopEntity, damage: Int) {
        self.damage = damage
        self.target = target
        
        // Sprite inicial vazio
        self.sprite = SKSpriteNode(texture: nil, size: CGSize(width: 9, height: 9))
        self.animationComponent = AnimationComponent(spriteNode: sprite)
        
        super.init()
        
        addComponent(animationComponent)
        addComponent(GKSKNodeComponent(node: sprite))
        
        sprite.position = origin
        sprite.zPosition = 2000 - sprite.position.y
        
        // animação inicial "cast" (nasce no mago)
        let castTextures = (1...5).map { SKTexture(imageNamed: "Sun_Magic_Cast_\($0)") }
        animationComponent.addAnimation(textures: castTextures, for: .custom("cast"), timePerFrame: 0.05, repeatForever: false)
        
        // animação do projétil voando
        let bulletTextures = (1...5).map { SKTexture(imageNamed: "Sun_Magic_Bullet_\($0)") }
        animationComponent.addAnimation(textures: bulletTextures, for: .custom("bullet"), timePerFrame: 0.05, repeatForever: true)
        
        // animação de impacto
        let contactTextures = (1...5).map { SKTexture(imageNamed: "Sun_Magic_Contact_\($0)") }
        animationComponent.addAnimation(textures: contactTextures, for: .custom("contact"), timePerFrame: 0.05, repeatForever: false)
        
        // começa com o "cast"
        animationComponent.runAnimation(for: .custom("cast"))
        
        // depois troca para "bullet"
        sprite.run(.sequence([
            .wait(forDuration: 0.35),
            .run { [weak self] in
                guard let self = self else { return }
                self.animationComponent.runAnimation(for: .custom("bullet"))
                
                // Adiciona rotação contínua para dar efeito fluido
                let rotate = SKAction.rotate(byAngle: .pi, duration: 0.3) // 180° em 0.3s
                let spin = SKAction.repeatForever(rotate)
                self.sprite.run(spin, withKey: "bulletSpin")
            }
        ]))
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public override func update(deltaTime seconds: TimeInterval) {
        guard let target = target,
              let targetPos = target.component(ofType: GKSKNodeComponent.self)?.node.position else { return }
        
        // move na direção do alvo
        let direction = CGVector(dx: targetPos.x - sprite.position.x, dy: targetPos.y - sprite.position.y)
        let length = sqrt(direction.dx*direction.dx + direction.dy*direction.dy)
        
        if length < 10 { // chegou no alvo
            explode(on: target)
            return
        }
        
        let normalized = CGVector(dx: direction.dx/length, dy: direction.dy/length)
        sprite.position.x += normalized.dx * speed * CGFloat(seconds)
        sprite.position.y += normalized.dy * speed * CGFloat(seconds)
    }
    
    private func explode(on target: TroopEntity) {
        // aplica dano
        if let health = target.component(ofType: HealthComponent.self) {
            health.takeDamage(damage)
            if health.isDead {
                target.stateMachineComponent.stateMachine.enter(TroopDieState.self)
            }
        }
        
        // troca para animação de impacto
        animationComponent.runAnimation(for: .custom("contact"))
        
        // remove depois da animação
        sprite.run(.sequence([
            .wait(forDuration: 0.25),
            .removeFromParent(),
            .run { [weak self] in
                self?.target = nil // solta a referência ao alvo
            }
        ]))
    }

}
