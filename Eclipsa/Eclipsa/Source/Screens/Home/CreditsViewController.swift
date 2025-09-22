import UIKit

final class CreditsViewController: UIViewController {
    
    // MARK: - Configuration Properties
    
    private let baseFontSize: CGFloat = 20
    private let titleFontSize: CGFloat = 28
    private let fadeDuration: TimeInterval = 2
    private let displayDuration: TimeInterval = 3.0
    
    var creditLines: [String] = (0...11).map { NSLocalizedString("credits.\($0)", comment: "") }
    
    var onFinished: (() -> Void)?
    
    // MARK: - Private Properties
    
    private let textLabel = UILabel()
    private var currentIndex = 0
    private var hasStarted = false
    private var hasFinished = false
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .black
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.alpha = 0
        textLabel.setContentHuggingPriority(.required, for: .vertical)
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        view.addSubview(textLabel)
        
        let guide = view.safeAreaLayoutGuide
        let maxWidthConstraint = textLabel.widthAnchor.constraint(lessThanOrEqualTo: guide.widthAnchor, multiplier: 2.0/3.0)
        maxWidthConstraint.priority = .required
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            maxWidthConstraint,
            textLabel.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: 24),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -24)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startIfNeeded()
    }
    
    // MARK: - Animation Sequence
    
    private func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        currentIndex = 0
        DispatchQueue.main.async { [weak self] in
            self?.showNextLine()
        }
    }
    
    private func showNextLine() {
        guard currentIndex < creditLines.count else {
            finishSequence()
            return
        }
        
        let line = creditLines[currentIndex]
        let fontSize: CGFloat = (currentIndex == 0 || currentIndex == creditLines.count - 1) ? titleFontSize : baseFontSize
        let font: UIFont
        if let custom = UIFont(name: "CCPixelArcade-Display", size: fontSize) {
            font = custom
        } else {
            font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.textLabel.alpha = 0
            self.textLabel.text = line
            self.textLabel.font = font
            self.textLabel.layoutIfNeeded()
            
            UIView.animate(withDuration: self.fadeDuration, animations: {
                self.textLabel.alpha = 1.0
            }, completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + self.displayDuration) {
                    UIView.animate(withDuration: self.fadeDuration, animations: {
                        self.textLabel.alpha = 0.0
                    }, completion: { _ in
                        self.currentIndex += 1
                        self.showNextLine()
                    })
                }
            })
        }
    }
    
    private func finishSequence() {
        guard !hasFinished else { return }
        hasFinished = true
        DispatchQueue.main.async { [weak self] in
            self?.onFinished?()
        }
    }
}
