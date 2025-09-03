import GameplayKit
import BehindGameKit

public class AttackComponent: GKComponent {
    private unowned let unit: BaseUnitEntity
    private var cooldown: TimeInterval
    private var lastAttackTime: TimeInterval = 0
    private var damage: Int
    
    public init(unit: BaseUnitEntity, damage: Int = 10, cooldown: TimeInterval = 2.0) {
        self.unit = unit
        self.damage = damage
        self.cooldown = cooldown
        super.init()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        let behaviorComponent = (unit.components.first { $0 is TroopBehaviorComponent } as? TroopBehaviorComponent)
        let target = behaviorComponent?.target as? BaseUnitEntity
        
        guard let target = target,
              let unitPos = unit.component(ofType: GKSKNodeComponent.self)?.node.position,
              let enemyPos = target.component(ofType: GKSKNodeComponent.self)?.node.position,
              let range = unit.component(ofType: RangeComponent.self)?.radius else { return }
        
        // ⚠️ nova checagem de time
        guard let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              let unitTeam = unit.component(ofType: TeamComponent.self)?.team,
              targetTeam != unitTeam else { return }
        
        let d2 = (unitPos.x - enemyPos.x) * (unitPos.x - enemyPos.x) + (unitPos.y - enemyPos.y) * (unitPos.y - enemyPos.y)
        
        if d2 <= range * range {
            if CACurrentMediaTime() - lastAttackTime >= cooldown {
                performAttack(on: target)
                lastAttackTime = CACurrentMediaTime()
            }
        }
    }
    
    public func tryAttack(on target: BaseUnitEntity) -> Bool {
        guard let unitTeam = unit.component(ofType: TeamComponent.self)?.team,
              let targetTeam = target.component(ofType: TeamComponent.self)?.team,
              unitTeam != targetTeam else { return false }
        
        if CACurrentMediaTime() - lastAttackTime >= cooldown {
            performAttack(on: target)
            lastAttackTime = CACurrentMediaTime()
            return true
        }
        return false
    }
    
    private func performAttack(on target: BaseUnitEntity) {
        guard let origin = unit.component(ofType: GKSKNodeComponent.self)?.node.position,
              let scene = unit.component(ofType: GKSKNodeComponent.self)?.node.scene else { return }
        
        let projectile = ProjectileEntity(from: origin, caster: unit, target: target, damage: damage)
        
        // adiciona o nó do projétil na cena
        if let node = projectile.component(ofType: GKSKNodeComponent.self)?.node {
            scene.addChild(node)
        }
        
        // registra projétil na cena (assim ele recebe update)
        scene.userData = scene.userData ?? NSMutableDictionary()
        var projectiles = scene.userData?["projectiles"] as? [ProjectileEntity] ?? []
        projectiles.append(projectile)
        scene.userData?["projectiles"] = projectiles
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
