//
//  CommandButton.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 15/08/25.
//
import SpriteKit

class CommandButton: SKNode {
    
    private let button: SKShapeNode
    
    var onTouch: (() -> Void)?
    
    init(position: CGPoint, name: String = "Default", color: UIColor = .red) {
        
        let buttonSize = CGSize(width: 64, height: 64)
        button = SKShapeNode(ellipseOf: buttonSize)
        button.fillColor = color
        button.strokeColor = color.withAlphaComponent(0.3)
        super.init()
        button.position = position
        button.zPosition = 1000
        button.name = name
        let label = SKLabelNode(text: name)
        label.fontName = "Avenir-Black"
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        isHidden = true
        addChild(button)
        }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func handleTouch(_ location: CGPoint){
        if !isHidden {
            let nodes = self.nodes(at: location)
            for node in nodes {
                if node.name == button.name {
                    onTouch?()
                }
            }
        }
    }
    
    func toggleCommand(value: Bool) {
        isHidden = value
        self.run(.fadeAlpha(to: isHidden ? 0 : 1, duration: 0.4))
    }
}
