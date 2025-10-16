// HealthBarComponent.swift
// Barra de vida visual para entidades
import SpriteKit
import GameplayKit

public class HealthBarComponent: GKComponent {
    private let barNode: SKShapeNode
    private let backgroundNode: SKShapeNode
    
    private let barHeight: CGFloat
    private let barWidth: CGFloat
    private let offsetY: CGFloat
    private let mainColor: SKColor
    
    private func applyAntiFlip() {
        guard let parentNode = entity?.component(ofType: GKSKNodeComponent.self)?.node else { return }
        let sign: CGFloat = parentNode.xScale < 0 ? -1 : 1
        backgroundNode.xScale = sign
        barNode.xScale = sign
    }
    
    public init(nodeHeight: CGFloat,
                width: CGFloat = 42,
                height: CGFloat = 7,
                color: SKColor = .systemGreen) {
        self.barWidth = width
        self.barHeight = height
        self.offsetY = nodeHeight / 2 + 12
        self.mainColor = color
        
        backgroundNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight),
                                     cornerRadius: barHeight/2)
        backgroundNode.fillColor = .black
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = 0.6

        barNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight),
                              cornerRadius: barHeight/2)
        barNode.strokeColor = .clear

        backgroundNode.name = "healthbar_background"
        barNode.name = "healthbar_bar"
        
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didAddToEntity() {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else { return }
        backgroundNode.position = CGPoint(x: 0, y: offsetY)
        barNode.position = CGPoint(x: 0, y: offsetY)
        if backgroundNode.parent == nil { node.addChild(backgroundNode) }
        if barNode.parent == nil { node.addChild(barNode) }
        updateBar(health: 1, max: 1)
        applyAntiFlip()
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        applyAntiFlip()
    }
    
    public override func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        backgroundNode.removeFromParent()
        barNode.removeFromParent()
    }
    
    public func updateBar(health: Int, max: Int) {
        let percent = max > 0 ? CGFloat(health) / CGFloat(max) : 0
        let width = barWidth * percent
        let rect = CGRect(x: -barWidth/2, y: -barHeight/2, width: width, height: barHeight)
        let path = CGPath(roundedRect: rect, cornerWidth: barHeight/2, cornerHeight: barHeight/2, transform: nil)
        barNode.path = path
        
        if let team = entity?.component(ofType: TeamComponent.self)?.team, team == .sun {
            barNode.fillColor = mainColor // usa a cor passada no init
        } else {
            // inimigos continuam com lógica antiga
            if percent < 0.2 {
                barNode.fillColor = .systemRed
            } else if percent < 0.5 {
                barNode.fillColor = .systemOrange
            } else {
                barNode.fillColor = .systemRed
            }
        }
    }
    
    public func hideHealthBar(_ bool: Bool) {
        barNode.isHidden =  bool
        backgroundNode.isHidden = bool
    }
}

