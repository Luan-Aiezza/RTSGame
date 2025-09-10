//
//  CommandButton.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 15/08/25.
//
import SpriteKit

class CommandButton: SKNode {
    
    private let button: SKShapeNode
    private var label: SKLabelNode?
    private var image: SKSpriteNode?
    
    var onTouch: (() -> Void)?
    
    init(position: CGPoint, name: String = "Default", color: UIColor = .red) {
        
        let buttonSize = CGSize(width: 50, height: 50)
        button = SKShapeNode(ellipseOf: buttonSize)
        button.fillColor = color
        button.strokeColor = color.withAlphaComponent(0.3)
        super.init()
        button.position = position
        button.zPosition = 1000
        button.name = name
        
        label = SKLabelNode(text: name)
        label!.fontName = "Avenir-Black"
        label!.fontSize = 22
        label!.fontColor = .white
        label!.verticalAlignmentMode = .center
        button.addChild(label!)
        isHidden = true
        addChild(button)
        }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func changeLabelToImage(with name: String){
        button.removeAllChildren()
        image = SKSpriteNode(imageNamed: name)
        image!.size = CGSize(width: 36, height: 36)
        image!.name = name
        button.addChild(image!)
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
