//
//  AimControlComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 12/08/25.
//

import Foundation
import GameplayKit
import SpriteKit
import Combine
import BehindGameKit

class AimControlComponent: GKComponent {
    
    var delegate: AimingDelegate
    private var subscriptions = Set<AnyCancellable>()
    
    public init(delegate: AimingDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupController(inputHandler: InputHandler, virtualController: AdaptedVirtualController?) {
        subscriptions.insert(inputHandler.$directionAxis.sink(receiveValue: { [weak self] direction in
            self?.delegate.handleAim(direction: direction, distance: 0)
        }))
        
        guard let virtualController else { return }
        subscriptions.insert(virtualController.creatAimObserver(completion: { direction, distance in
            self.delegate.handleAim(direction: direction, distance: distance)
            
        }))
    }
}


protocol AimingDelegate: AnyObject {
    func handleAim(direction: CGPoint, distance: CGFloat)
}
