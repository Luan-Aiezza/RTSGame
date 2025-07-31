import GameplayKit

/// Componente responsável por controlar o estado de animação de uma entidade
public class StateComponent: GKComponent {
    public enum State {
        case idle
        case walking
    }
    
    public private(set) var currentState: State = .idle

    public func updateState(moving: Bool) {
        let newState: State = moving ? .walking : .idle
        if newState != currentState {
            currentState = newState
            notifyAnimationComponent()
        }
    }
    
    private func notifyAnimationComponent() {
        guard let animationComponent = entity?.component(ofType: AnimationComponent.self) else { return }
        switch currentState {
        case .idle:
            animationComponent.runAnimation(for: .idle)
        case .walking:
            animationComponent.runAnimation(for: .walk)
        }
    }
}
