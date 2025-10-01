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
    private var skipButton: UIButton!
    private var currentIndex = 0
    private var hasStarted = false
    private var hasFinished = false
    
    // MARK: - Lifecycle
    override func loadView() {
        super.loadView()
        AudioManager.shared.fadeInBackgroundMusic(named: "OST_Credits")
        view.backgroundColor = .black
        
        // Texto central dos créditos
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.alpha = 0
        textLabel.setContentHuggingPriority(.required, for: .vertical)
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        view.addSubview(textLabel)
        
        // Botão skip
        setupSkipButton()
        
        // Layout
        let guide = view.safeAreaLayoutGuide
        let maxWidthConstraint = textLabel.widthAnchor.constraint(lessThanOrEqualTo: guide.widthAnchor, multiplier: 2.0/3.0)
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
    
    // MARK: - Setup Skip Button
    private func setupSkipButton() {
        skipButton = UIButton(type: .system)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle(NSLocalizedString("skip", comment: ""), for: .normal)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.titleLabel?.font = UIFont(name: "PixelifySans-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20)
        skipButton.alpha = 1.0
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(skipButton)
        
        // Layout canto superior direito
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
        
        // Efeito piscando infinito
        animateSkipBlink()
    }
    
    private func animateSkipBlink() {
        skipButton.alpha = 1.0
        UIView.animate(withDuration: 0.7,
                       delay: 0,
                       options: [.allowUserInteraction],
                       animations: { [weak self] in
            self?.skipButton.alpha = 0.2
        }, completion: { [weak self] _ in
            UIView.animate(withDuration: 0.7,
                           delay: 0,
                           options: [.autoreverse, .repeat, .allowUserInteraction],
                           animations: { [weak self] in
                self?.skipButton.alpha = 1.0
            })
        })
    }

    
    @objc private func skipTapped() {
        finishSequence()
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
        let font = UIFont(name: "CCPixelArcade-Display", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .regular)
        
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
        let preStopDelay: TimeInterval = 1.0
        
        AudioManager.shared.fadeOutBackgroundMusic(duration: preStopDelay, stopAfter: true)
        
        // Sumir texto + skip juntos
        UIView.animate(withDuration: 0.5) {
            self.textLabel.alpha = 0
            self.skipButton.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + preStopDelay) { [weak self] in
            self?.onFinished?()
        }
    }
}
