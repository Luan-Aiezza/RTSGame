import UIKit
import SpriteKit

final class ConfigViewController: UIViewController {
    private weak var flowDelegate: ConfigFlowDelegate?
    // MARK: - UI
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Menu_Background"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let overlayView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black
        v.alpha = 0.8
        return v
    }()
    
    private let contentStack: UIStackView = {
        let st = UIStackView()
        st.translatesAutoresizingMaskIntoConstraints = false
        st.axis = .vertical
        st.alignment = .fill
        st.spacing = 16
        return st
    }()
    
    private let backButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(NSLocalizedString("back", comment: ""), for: .normal)
        bt.setTitleColor(.white, for: .normal)
        if let joystickFont = UIFont(name: "CCPixelArcade-Display", size: 18) {
            bt.titleLabel?.font = joystickFont
        } else {
            bt.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        }
        return bt
    }()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.text = NSLocalizedString("configTitle", comment: "")
        lb.textColor = .yellow
        lb.textAlignment = .center
        if let joystickFont = UIFont(name: "CCPixelArcade-Display", size: 28) {
            lb.font = joystickFont
        } else {
            lb.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        }
        return lb
    }()
    
    private func makeSubtitleButton(title: String) -> UIButton {
        let bt = UIButton(type: .system)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(title, for: .normal)
        bt.setTitleColor(.white, for: .normal)
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 20) {
            bt.titleLabel?.font = joystickFont
        } else {
            bt.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        }
        return bt
    }
    
    private lazy var tutorialButton: UIButton = { makeSubtitleButton(title: "Tutorial") }()
    private lazy var creditsButton: UIButton = { makeSubtitleButton(title: NSLocalizedString("configCredits", comment: "")) }()
    
    // Custom discrete slider (10 steps) with yellow knob and value label
    private let musicControl = DiscreteSliderRow(title: NSLocalizedString("configMusic", comment: ""))
    private let effectsControl = DiscreteSliderRow(title: NSLocalizedString("configEffects", comment: ""))
    
    // MARK: - Init
    init(flowDelegate: ConfigFlowDelegate) {
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        tutorialButton.addTarget(self, action: #selector(handleTutorial), for: .touchUpInside)
        creditsButton.addTarget(self, action: #selector(handleCredits), for: .touchUpInside)
        
        // Initialize sliders with persisted values
        musicControl.step = AudioManager.shared.musicVolumeStep
        effectsControl.step = AudioManager.shared.effectsVolumeStep
        
        // Update AudioManager (and persist) on user changes
        musicControl.onStepChanged = { step in
            AudioManager.shared.musicVolumeStep = step
        }
        effectsControl.onStepChanged = { step in
            AudioManager.shared.effectsVolumeStep = step
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(backgroundImageView)
        view.addSubview(overlayView)
        view.addSubview(contentStack)
        view.addSubview(backButton)
        
        // Stack content
        contentStack.addArrangedSubview(titleLabel)
        contentStack.setCustomSpacing(24, after: titleLabel)
        contentStack.addArrangedSubview(tutorialButton)
        contentStack.addArrangedSubview(creditsButton)
        contentStack.setCustomSpacing(24, after: creditsButton)
        contentStack.addArrangedSubview(musicControl)
        contentStack.addArrangedSubview(effectsControl)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
        
        // Ensure rows expand to full width and align the start of the tracks
        musicControl.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor).isActive = true
        musicControl.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor).isActive = true
        effectsControl.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor).isActive = true
        effectsControl.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor).isActive = true
        // Align the track leading anchors so the sliders start at the same X regardless of label length
        musicControl.alignmentTrackLeadingAnchor.constraint(equalTo: effectsControl.alignmentTrackLeadingAnchor).isActive = true
    }
    
    @objc private func handleBack() {
        flowDelegate?.backHome()
    }
    
    @objc private func handleTutorial() {
        // Placeholder action
        flowDelegate?.goTutorial()
    }
    
    @objc private func handleCredits() {
        // Apresenta a tela de créditos em UIKit (substitui SpriteKit)
        flowDelegate?.presentCredits()
    }
}


protocol ConfigFlowDelegate: AnyObject {
    func presentCredits()
    func backHome()
    func goTutorial()
}
