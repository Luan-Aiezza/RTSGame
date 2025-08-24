// Nova entidade base para personagens do jogo
import SpriteKit
import GameplayKit
import BehindGameKit

public class BaseUnitEntity: GKEntity {
    public var stateMachineComponent: StateMachineComponent!
    
    public init(team: Team = .sun, maxHealth: Int, spriteSize: CGSize, idleTextures: [SKTexture], walkTextures: [SKTexture]) {
        super.init()

        let spriteNode = SKSpriteNode(texture: nil, color: .clear, size: spriteSize)
        self.addComponent(GKSKNodeComponent(node: spriteNode))

        // Componente de animação
        let animationComponent = AnimationComponent(spriteNode: spriteNode)
        animationComponent.addAnimation(textures: idleTextures, for: .idle, timePerFrame: 0.12)
        animationComponent.addAnimation(textures: walkTextures, for: .walk, timePerFrame: 0.10)
        self.addComponent(animationComponent)

        // Estado e máquina de estados
        let idleState = IdleState(entity: self)
        let walkingState = WalkingState(entity: self)
        let stateMachine = GKStateMachine(states: [idleState, walkingState])
        self.stateMachineComponent = StateMachineComponent(stateMachine)
        self.addComponent(stateMachineComponent)

        self.addComponent(TeamComponent(team: team)) // Antes do HealthBar para cor correta

        // Componente de Vida
        let healthComponent = HealthComponent(maxHealth: maxHealth)
        self.addComponent(healthComponent)

        let healthBar = HealthBarComponent()
        self.addComponent(healthBar)
        healthComponent.onHealthChanged = { [weak healthBar] health, max in
            healthBar?.updateBar(health: health, max: max)
        }
        healthBar.updateBar(health: healthComponent.currentHealth, max: healthComponent.maxHealth)

        let rangeComponent = RangeComponent(radius: 120)
        self.addComponent(rangeComponent)

        // Adiciona AgentComponent padrão (detalhes podem ser sobrescritos nas subclasses)
        let agent = AgentComponent(node: spriteNode)
        agent.agent.radius = 32
        agent.agent.maxSpeed = 100
        agent.agent.maxAcceleration = 300
        self.addComponent(agent)
    }

    var moveComponent: MovementComponent? {
        return self.component(ofType: MovementComponent.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
