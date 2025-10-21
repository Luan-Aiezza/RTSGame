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
    private var costOverlay: SKSpriteNode?
    
    var onTouch: (() -> Void)?
    
    init(position: CGPoint, name: String = "Default", color: UIColor = .red) {
        
        let buttonSize = CGSize(width: 47, height: 47)
        button = SKShapeNode(ellipseOf: buttonSize)
        button.fillColor = color.withAlphaComponent(0.5)
        button.strokeColor = color
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
        image!.size = CGSize(width: 30, height: 30)
        image!.name = name
        image!.texture?.filteringMode = .nearest
        button.addChild(image!)
        if let overlay = costOverlay {
            overlay.removeFromParent()
            button.addChild(overlay)
        }
    }
    
    public func changeButtonColors(buttonColor: UIColor?, strokeColor: UIColor?){
        if let strokeColor = strokeColor{
            button.strokeColor = strokeColor
            button.lineWidth = 3
        }
        if let buttonColor = buttonColor{
            button.fillColor = buttonColor
        }
    }
    
    public func setCostOverlayImage(named name: String?, position: CGPoint? = nil, scale: CGFloat = 0.1) {
        costOverlay?.removeFromParent()
        costOverlay = nil
        guard let name, !name.isEmpty else { return }
        let overlay = SKSpriteNode(imageNamed: name)
        overlay.name = "CostOverlay_\(name)"
        overlay.zPosition = 11 // must be above icon image
        overlay.setScale(scale)
        let buttonSize = button.frame.size
        overlay.position = position ?? CGPoint(
            x: buttonSize.width / 2 - overlay.size.width * 0.4,
            y: -buttonSize.height / 2 + overlay.size.height * 0.4
        )
        button.addChild(overlay)
        costOverlay = overlay
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

