//
//  GameControllerProtocol.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 29/07/25.
//

import GameController
import Foundation

protocol GameControllerProtocol: AnyObject {
    func setupVirtualController()
    func virtualControllerDidDisconnect(notification: Notification)
    
}
