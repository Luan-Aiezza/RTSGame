import Foundation
import SpriteKit
import Combine
import BehindGameKit

public class AdaptedVirtualController: ObservableObject, AimAdapter{
    
    private var analogNode: AdaptedAnalogNode

    // Tap detection state
    private var touchBeganTimestamp: TimeInterval?
    private var didMoveDuringTouch: Bool = false
    public var onTap: (() -> Void)?
    public var onTouchBegan: (() -> Void)?
    
    public init(scene: SKScene, analogRadius: CGFloat = 20, color: UIColor = .white) {
        analogNode = AdaptedAnalogNode(radius: analogRadius)
        
        if (scene.camera != nil) {
            scene.camera?.addChild(analogNode)
        } else {
            scene.addChild(analogNode)
        }
        
        setup(scene: scene)
        analogNode.changeAnalogColor(color: color)
    }
    
    private func setup(scene: SKScene) {
        analogNode.zPosition = 999
        
        // Position
        guard let sceneSize = scene.view?.frame.size else { return }
        let analogSize = analogNode.calculateAccumulatedFrame().size
        analogNode.position.x = -sceneSize.width/2 + analogSize.width + sceneSize.width/8
        analogNode.position.y = -sceneSize.height/2 + analogSize.height + sceneSize.height/8
    }
    
    public func createAnalogObserver(delegate: @escaping (CGPoint) -> Void) -> AnyCancellable {
        return analogNode.$direction.sink(receiveValue: delegate)
    }
    
    public func setAnalogVisible(value: Bool, withDuration duration: TimeInterval = 0) {
        analogNode.setVisible(value: value, withDuration: duration)
    }
    
    public func changePosition(_ position: CGPoint) {
        analogNode.position = position
    }
    
    public func getAnalogSize() -> CGSize {
        return analogNode.calculateAccumulatedFrame().size
    }
    
    public func touchBegan(_ touches: SetTouches, with event: UIEventAlias?) {
        // Prepare for tap detection
        didMoveDuringTouch = false
        #if os(iOS) || os(tvOS)
        if let first = touches.first {
            touchBeganTimestamp = first.timestamp
        } else {
            touchBeganTimestamp = nil
        }
        #elseif os(macOS)
        touchBeganTimestamp = event?.timestamp
        #else
        touchBeganTimestamp = nil
        #endif

        onTouchBegan?()
        analogNode.touchesBeganAlias(touches, with: event)
    }
    
    public func touchMoved(_ touches: SetTouches, with event: UIEventAlias?) {
        didMoveDuringTouch = true

        if analogNode.isVisible {
            analogNode.touchesMovedAlias(touches, with: event)
        }
    }
    
    public func touchesEnded(_ touches: SetTouches, with event: UIEventAlias?) {
        // Detect tap (no movement and short press)
        var isShortPress = true
        #if os(iOS) || os(tvOS)
        if let start = touchBeganTimestamp, let end = touches.first?.timestamp {
            isShortPress = (end - start) < 0.25
        }
        #elseif os(macOS)
        if let start = touchBeganTimestamp, let end = event?.timestamp {
            isShortPress = (end - start) < 0.25
        }
        #endif
        if !didMoveDuringTouch && isShortPress {
            onTap?()
        }
        // reset state
        touchBeganTimestamp = nil
        didMoveDuringTouch = false

        analogNode.touchesEndedAlias(touches, with: event)
    }
    
    public func touchesCancelled(_ touches: SetTouches, with event: UIEventAlias?) {
        // reset state
        touchBeganTimestamp = nil
        didMoveDuringTouch = false

        analogNode.touchesCancelledAlias(touches, with: event)
    }
}

protocol AimAdapter {
    func creatAimObserver(completion: @escaping (CGPoint, CGFloat) -> Void) -> AnyCancellable
}

// MARK: criar observadores para Mira
extension AdaptedVirtualController {
    public func creatAimObserver(completion: @escaping (CGPoint, CGFloat) -> Void) -> AnyCancellable {
        return Publishers.CombineLatest(analogNode.$direction, analogNode.$distance).sink{ direction, distance in
            completion(direction, distance)
        }
    }
}

