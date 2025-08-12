import Foundation
import GameplayKit
import SpriteKit
import Combine
import BehindGameKit

public class AdaptedControlableComponent: GKComponent {
    
    var delegate: ControlableDelegate
    private var subscriptions = Set<AnyCancellable>()
    
    public init(delegate: ControlableDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupController(inputHandler: InputHandler, virtualController: AdaptedVirtualController?) {
        subscriptions.insert(inputHandler.$directionAxis.sink(receiveValue: { [weak self] direction in
            self?.delegate.handleMovement(direction: direction)
        }))
        
        subscriptions.insert(inputHandler.$buttonAPressed.sink(receiveValue: { [weak self] isPressed in
            if isPressed {
                self?.delegate.handleButtonAPressed()
            }
        }))
        
        guard let virtualController else { return }
        subscriptions.insert(virtualController.createAnalogObserver(delegate: { [weak self] direction in
            self?.delegate.handleMovement(direction: direction)
        }))
    }
}
