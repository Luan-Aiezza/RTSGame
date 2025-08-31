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
    
    public override init() {
        backgroundNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: barHeight/2)
        backgroundNode.fillColor = .black
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = 0.6

        
        barNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: barHeight/2)
        barNode.strokeColor = .clear

        backgroundNode.name = "healthbar_background"
        barNode.name = "healthbar_bar"
        
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didAddToEntity() {
        super.didAddToEntity()
        // Define cor da barra conforme o time
        if let team = entity?.component(ofType: TeamComponent.self)?.team {
            switch team {
            case .sun:
                barNode.fillColor = .green
            case .moon:
                barNode.fillColor = .red
            default:
                barNode.fillColor = .green
            }
        } else {
            barNode.fillColor = .green
        }
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
        
        // Ajusta a cor da barra conforme o time e o percentual de vida
        if let team = entity?.component(ofType: TeamComponent.self)?.team {
            switch team {
            case .moon:
                barNode.fillColor = .red
            case .sun:
                if percent < 0.2 {
                    barNode.fillColor = .red
                } else if percent < 0.5 {
                    barNode.fillColor = .orange
                } else {
                    barNode.fillColor = .green
                }
            default:
                if percent < 0.2 {
                    barNode.fillColor = .red
                } else if percent < 0.5 {
                    barNode.fillColor = .orange
                } else {
                    barNode.fillColor = .green
                }
            }
        } else {
            if percent < 0.2 {
                barNode.fillColor = .red
            } else if percent < 0.5 {
                barNode.fillColor = .orange
            } else {
                barNode.fillColor = .green
            }
        }
    }
}

