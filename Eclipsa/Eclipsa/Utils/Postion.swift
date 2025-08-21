//
//  Postions.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 20/08/25.
//
import SpriteKit

struct Positions {
    static func cancelButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 - 80, y: size.height/2 - 80)
    }
    
    static func releaseButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 + 80, y: -size.height/2 + 180)
    }
}
