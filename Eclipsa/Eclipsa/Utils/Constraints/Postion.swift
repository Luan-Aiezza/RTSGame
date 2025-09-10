//
//  Postions.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 20/08/25.
//
import SpriteKit

enum Position {
    static func cancelButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 - 80, y: size.height/2 - 80)
    }
    
    static func releaseButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 - 80, y: -size.height/2 + 180)
    }
    
    static func followButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 - 80, y: -size.height/2 + 80)
    }
    
    static func invokeMeleeButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 - 160, y: -size.height/2 + 80)
    }
    
    static func invokeRangeButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2 - 240, y: -size.height/2 + 80)
    }
    
    static func resourceLabel(size: CGSize) -> CGPoint {
        return CGPoint(x: -size.width/3, y: size.height/3)
    }
}
