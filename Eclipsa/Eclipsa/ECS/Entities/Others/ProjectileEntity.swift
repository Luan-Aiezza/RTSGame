import SpriteKit
import GameplayKit
import BehindGameKit

public class ProjectileEntity: GKEntity {
    private let damage: Int
    private weak var target: BaseUnitEntity?
    private let speed: CGFloat = 180.0 // px/segundo
    
    private var bullet: SKSpriteNode
    private var animationComponent: AnimationComponent
    
    init(from origin: CGPoint, caster: BaseUnitEntity, target: BaseUnitEntity, damage: Int) {
        self.damage = damage
        self.target = target
        self.bullet = SKSpriteNode(texture: nil, size: CGSize(width: 16, height: 16))
        self.animationComponent = AnimationComponent(spriteNode: bullet)

        super.init()
        
        addComponent(animationComponent)
        addComponent(GKSKNodeComponent(node: bullet))
        
        bullet.position = origin
        bullet.zPosition = 2000 - bullet.position.y
        bullet.isHidden = true
        
        // ============================
        // 2) Bullet animação
        // ============================
        let bulletTextures = (1...4).map { SKTexture(imageNamed: "Sun_Magic_Bullet_\($0)") }
        animationComponent.addAnimation(
            textures: bulletTextures,
            for: .custom("bullet"),
            timePerFrame: 0.07,
            repeatForever: true
        )
        
        
        // Como o cast agora está acoplado ao personagem, não precisamos mais do castNode/castTextures.
        // Basta iniciar o projétil.
        startBullet()
        
        // ============================
        // 3) Hit animação (32x32 → corrigir base)
        // ============================
        let contactTextures = (1...13).map { SKTexture(imageNamed: "Sun_Magic_Hit_\($0)") }
        animationComponent.addAnimation(
            textures: contactTextures,
            for: .custom("contact"),
            timePerFrame: 0.06,
            repeatForever: false
        )
    
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func startBullet() {
        bullet.isHidden = false
        animationComponent.runAnimation(for: .custom("bullet"))
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        guard !bullet.isHidden else { return }
        
        // ✅ Verifica se o target ainda existe e está vivo
        guard let target = target,
              let targetNode = target.component(ofType: GKSKNodeComponent.self)?.node,
              targetNode.parent != nil else {
            // alvo sumiu → remover bullet
            cleanup()
            return
        }
        
        let targetPos = targetNode.position
        
        // direção
        let direction = CGVector(dx: targetPos.x - bullet.position.x,
                                 dy: targetPos.y - bullet.position.y)
        let length = sqrt(direction.dx*direction.dx + direction.dy*direction.dy)
        
        if length < 12 {
            explode(on: target)
            return
        }
        
        // normaliza
        let normalized = CGVector(dx: direction.dx/length, dy: direction.dy/length)
        bullet.position.x += normalized.dx * speed * CGFloat(seconds)
        bullet.position.y += normalized.dy * speed * CGFloat(seconds)
        
        // flip no eixo X de acordo com posição relativa
        bullet.xScale = targetPos.x < bullet.position.x ? -1 : 1
    }

    
    private func explode(on target: BaseUnitEntity) {
        if let health = target.component(ofType: HealthComponent.self) {
            health.takeDamage(damage)
            
            if health.isDead, let troop = target as? TroopEntity {
                troop.stateMachineComponent.stateMachine.enter(TroopDieState.self)
            }
        }
        
        // troca bullet -> animação de impacto (32x32 → corrigir base)
        bullet.size = CGSize(width: 32, height: 32)
        bullet.position = CGPoint(
            x: bullet.position.x,  // desloca levemente à esquerda
            y: bullet.position.y   // sobe para alinhar base
        )
        
        animationComponent.runAnimation(for: .custom("contact"))
        
        bullet.run(.sequence([
            .wait(forDuration: 0.4),
            .removeFromParent(),
            .run { [weak self] in self?.target = nil }
        ]))
    }
    
    private func cleanup() {
        bullet.removeAllActions()
        bullet.removeFromParent()
        target = nil
    }
}
