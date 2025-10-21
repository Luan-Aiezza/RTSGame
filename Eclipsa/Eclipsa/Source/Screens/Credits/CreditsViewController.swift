import UIKit

final class CreditsViewController: UIViewController {
    
    // MARK: - Configuration Properties
    private let baseFontSize: CGFloat = 20
    private let titleFontSize: CGFloat = 28
    private let fadeDuration: TimeInterval = 2
    private let displayDuration: TimeInterval = 2.0
    
    var creditLines: [String] = (0...14).map { NSLocalizedString("credits.\($0)", comment: "") }
    var onFinished: (() -> Void)?
    
    // MARK: - Private Properties
    private let textLabel = UILabel()
    private var skipButton: UIButton!
    private var currentIndex = 0
    private var hasStarted = false
    private var hasFinished = false
    
    // Controle de animação ativa
    private var isShowingLine = false
    private var currentWorkItem: DispatchWorkItem?
    
    // MARK: - Lifecycle
    override func loadView() {
        super.loadView()
        AudioManager.shared.playBackgroundMusic(named: "OST_Credits")
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
        
        // Toque em qualquer lugar = skip atual
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
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

    // MARK: - Actions
    @objc private func viewTapped() {
        // Se já acabou, ignora
        guard !hasFinished else { return }
        // Se está mostrando linha, apenas pula
        if isShowingLine {
            skipCurrentLine()
        }
    }
    
    @objc private func skipTapped() {
        finishSequence()
    }
    
    // MARK: - Animation Sequence
    private func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        currentIndex = 0
        showNextLine()
    }
    
    private func showNextLine() {
        guard currentIndex < creditLines.count else {
            finishSequence()
            return
        }
        
        isShowingLine = true
        currentWorkItem?.cancel()
        
        let line = creditLines[currentIndex]
        let fontSize: CGFloat = (currentIndex == 0 || currentIndex == creditLines.count - 1) ? titleFontSize : baseFontSize
        let font = UIFont(name: "CCPixelArcade-Display", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .regular)
        
        textLabel.alpha = 0
        textLabel.text = line
        textLabel.font = font
        textLabel.layoutIfNeeded()
        
        UIView.animate(withDuration: fadeDuration, animations: {
            self.textLabel.alpha = 1.0
        }, completion: { _ in
            // Espera displayDuration e troca de linha
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: self.fadeDuration, animations: {
                    self.textLabel.alpha = 0.0
                }, completion: { _ in
                    self.currentIndex += 1
                    self.isShowingLine = false
                    self.showNextLine()
                })
            }
            self.currentWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + self.displayDuration, execute: workItem)
        })
    }
    
    // MARK: - Skip line instantâneo
    private func skipCurrentLine() {
        guard isShowingLine else { return }
        // Cancela a espera programada
        currentWorkItem?.cancel()
        currentWorkItem = nil
        
        // Faz o fade-out atual rapidamente
        UIView.animate(withDuration: 0.3, animations: {
            self.textLabel.alpha = 0.0
        }, completion: { _ in
            self.isShowingLine = false
            self.currentIndex += 1
            self.showNextLine()
        })
    }
    
    private func finishSequence() {
        guard !hasFinished else { return }
        hasFinished = true
        
        AudioManager.shared.fadeOutBackgroundMusic(duration: 1.0, stopAfter: true)
        
        // Sumir texto + skip juntos
        UIView.animate(withDuration: 0.5) {
            self.textLabel.alpha = 0
            self.skipButton.alpha = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.onFinished?()
        }
    }
}
