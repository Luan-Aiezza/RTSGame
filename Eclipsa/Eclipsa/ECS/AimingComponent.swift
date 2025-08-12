//
//  DraggableComponent.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 07/08/25.
//

import GameplayKit

class AimingComponent: GKComponent {
    var isAiming: Bool = false
    var startPoint: CGPoint = .zero
    var endPoint: CGPoint = .zero
    var maxRange: Float = 200
}


struct AimingResult {
    let startPoint: CGPoint
    let endPoint: CGPoint
}
