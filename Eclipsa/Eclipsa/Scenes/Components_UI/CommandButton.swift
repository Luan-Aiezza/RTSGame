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
    
    init(size: CGSize) {
        
        let buttonSize = CGSize(width: 64, height: 64)
        button = SKShapeNode(ellipseOf: buttonSize)
        button.fillColor = .red
        button.strokeColor = .darkGray
        super.init()
        let x =  size.width/2 - 80
        let y =  size.height/2 - 80
        button.position = CGPoint(x:  x, y:  y)
        button.zPosition = 1000
        button.name = "cancelButton"
        let label = SKLabelNode(text: "Cancel")
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
    
    func handleTouch(_ location: CGPoint){
        if !isHidden {
            let nodes = self.nodes(at: location)
            for node in nodes {
                if node.name == "cancelButton" {
                    onTouch?()
                    toggleCommand(value: true)
                }
            }
        }
    }
    
    func toggleCommand(value: Bool) {
        isHidden = value
        self.run(.fadeAlpha(to: isHidden ? 0 : 1, duration: 0.4))
    }
}
