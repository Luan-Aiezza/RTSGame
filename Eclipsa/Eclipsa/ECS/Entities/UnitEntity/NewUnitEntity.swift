//
//  NewUnitEntity.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 22/08/25.
//
import GameplayKit

class NewUnitEntity: GKEntity {
    init(team: Team, range: CGFloat, maxHealth: Int = 100) {
        super.init()
        self.addComponent(TeamComponent(team: team))
        
        let spriteNode = SKSpriteNode(texture: nil, color: .clear, size: CGSize(width: 100, height: 100))
        spriteNode.color = .blue
        self.addComponent(GKSKNodeComponent(node: spriteNode))
        self.addComponent(RangeComponent(radius: range))
        self.addComponent(AnimationComponent(spriteNode: spriteNode))
        
        setupAnimationComponent()
        setupHealthComponent(maxHealth: maxHealth)
    }
   
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupHealthComponent(maxHealth: Int){
        let healthComponent = HealthComponent(maxHealth: maxHealth)
        self.addComponent(healthComponent)
        
        let healthBar = HealthBarComponent()
        self.addComponent(healthBar)
        
        healthComponent.onHealthChanged = { [weak healthBar] health, max in
            healthBar?.updateBar(health: health, max: max)
        }
        healthBar.updateBar(health: healthComponent.currentHealth, max: healthComponent.maxHealth)
    }
    
    public func setupAnimationComponent(){
         let config = AnimationConfig(
            assetName: "Sun_Hero_",
            assetQuantity: [
                .idle: 24,
                .walk: 5
            ],
            actionAndTimePerFrame: [
                .idle: 0.12,
                .walk: 0.10
            ])
        self.component(ofType: AnimationComponent.self)?.configureAnimation(config: config)
    }
    
}
