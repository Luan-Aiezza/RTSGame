// HealthBarComponent.swift
// Barra de vida visual para entidades
import SpriteKit
import GameplayKit

public class HealthBarComponent: GKComponent {
    private let barNode: SKShapeNode
    private let backgroundNode: SKShapeNode
    private let barHeight: CGFloat = 7
    private let barWidth: CGFloat = 42
    private let offsetY: CGFloat = 38 // Ajuste para ficar abaixo do sprite
    
    public init(color: SKColor = .green) {
        backgroundNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: barHeight/2)
        backgroundNode.fillColor = .black
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = 0.6
        backgroundNode.zPosition = 1100
        
        barNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: barHeight/2)
        barNode.fillColor = color
        barNode.strokeColor = .clear
        barNode.zPosition = 1101
        
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didAddToEntity() {
        super.didAddToEntity()
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else { return }
        backgroundNode.position = CGPoint(x: 0, y: offsetY)
        barNode.position = CGPoint(x: 0, y: offsetY)
        if backgroundNode.parent == nil { node.addChild(backgroundNode) }
        if barNode.parent == nil { node.addChild(barNode) }
        updateBar(health: 1, max: 1) // Começa cheia
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
        if percent < 0.2 {
            barNode.fillColor = .red
        } else if percent < 0.5 {
            barNode.fillColor = .orange
        } else {
            barNode.fillColor = .green
        }
    }
}
