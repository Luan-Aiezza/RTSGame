//
//  FontManager.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 08/09/25.
//


import Foundation
import SwiftUI

public struct FontManager {
    public static func registerFonts() {
        registerFont(bundle: Bundle.main , fontName: "CCPixelArcade-Display", fontExtension: "otf")
        registerFont(bundle: Bundle.main , fontName: "CCPixelArcade-Joystick", fontExtension: "otf")
        registerFont(bundle: Bundle.main , fontName: "SquareDance00", fontExtension: "ttf")
        registerFont(bundle: Bundle.main , fontName: "SquareDance10", fontExtension: "ttf")
    }
    fileprivate static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) {
        
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            fatalError("Couldn't create font from data")
        }
        
        var error: Unmanaged<CFError>?
        
        CTFontManagerRegisterGraphicsFont(font, &error)
    }
}
