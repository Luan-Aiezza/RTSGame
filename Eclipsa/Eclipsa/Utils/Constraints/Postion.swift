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
    
    static func invokeMeleeButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/3 - 40, y: -size.height/2 + 120)
    }
    
    static func followButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/3 - 90, y: -size.height/2 + 60)
    }
    
    static func invokeRangeButton(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/3 + 10, y: -size.height/2 + 60)
    }
    
    static func resourceLabel(size: CGSize) -> CGPoint {
        return CGPoint(x: -size.width/3, y: size.height/3)
    }
    
    static func gameController(size: CGSize) -> CGPoint {
        return CGPoint(x: -size.width/2.7 , y: -size.height/3.7)
    }
    
    static func commandController(size: CGSize) -> CGPoint {
        return CGPoint(x: size.width/2.7 , y: -size.height/3.7)
    }
}
