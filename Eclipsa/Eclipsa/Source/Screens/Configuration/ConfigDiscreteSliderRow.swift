//
//  ConfigDiscreteSliderRow.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 20/09/25.
//
import UIKit
// MARK: - DiscreteSliderRow
final class DiscreteSliderRow: UIView {
    private let titleLabel = UILabel()
    private let trackView = UIView()
    private let knobView = UIView()
    private let valueLabel = UILabel()

    private var knobLeadingConstraint: NSLayoutConstraint?

    private let steps: Int = 10 // 10 pontos
    private var currentStep: Int = 4 { didSet { updateUI() } }

    // Public API: observe step changes and configure initial step (1...10)
    var onStepChanged: ((Int) -> Void)?

    var step: Int {
        get { currentStep + 1 }
        set {
            let clamped = max(1, min(newValue, steps))
            currentStep = clamped - 1
            onStepChanged?(clamped)
        }
    }

    private let trackHeight: CGFloat = 6
    private let knobSize: CGFloat = 18 // bolinha amarela

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup(title: title)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup(title: String) {
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.textColor = .white
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 20) {
            titleLabel.font = joystickFont
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        }

        // Track
        trackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.backgroundColor = .white
        trackView.layer.cornerRadius = trackHeight/2
        trackView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        trackView.layer.borderWidth = 1

        // Knob
        knobView.translatesAutoresizingMaskIntoConstraints = false
        knobView.backgroundColor = .yellow
        knobView.layer.cornerRadius = knobSize/2
        knobView.layer.shadowColor = UIColor.black.cgColor
        knobView.layer.shadowOpacity = 0.3
        knobView.layer.shadowRadius = 2
        knobView.layer.shadowOffset = CGSize(width: 0, height: 1)

        // Value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.textColor = .white
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 16) {
            valueLabel.font = joystickFont
        } else {
            valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
        valueLabel.textAlignment = .right

        // Priorities to keep the track visible
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        trackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        trackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(titleLabel)
        addSubview(trackView)
        addSubview(valueLabel)
        addSubview(knobView)
        bringSubviewToFront(knobView)

        NSLayoutConstraint.activate([
            // Title on the left
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Value on the right
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Track between title and value
            trackView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            trackView.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -12),
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.heightAnchor.constraint(equalToConstant: trackHeight),
            trackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),

            // Ensure minimum height for the row to fit the knob
            heightAnchor.constraint(greaterThanOrEqualToConstant: max(trackHeight, knobSize)),

            // Knob on top of the track
            knobView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            knobView.widthAnchor.constraint(equalToConstant: knobSize),
            knobView.heightAnchor.constraint(equalToConstant: knobSize)
        ])

        knobLeadingConstraint = knobView.centerXAnchor.constraint(equalTo: trackView.leadingAnchor)
        knobLeadingConstraint?.isActive = true

        // Pan gesture to move knob
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        knobView.addGestureRecognizer(pan)
        knobView.isUserInteractionEnabled = true

        updateUI()
    }

    private func stepWidth() -> CGFloat {
        let total = trackView.bounds.width
        guard steps > 1 else { return total }
        return total / CGFloat(steps - 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        placeKnob(animated: false)
    }

    private func updateUI() {
        valueLabel.text = "\(currentStep + 1)"
        placeKnob(animated: true)
        onStepChanged?(currentStep + 1)
    }

    private func placeKnob(animated: Bool) {
        // Ensure track has a valid width before positioning
        guard trackView.bounds.width > 0 else { return }
        let x = xPosition(for: currentStep)
        let actions = {
            let relative = x - self.trackView.frame.minX
            self.knobLeadingConstraint?.constant = relative
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.12, animations: actions)
        } else {
            actions()
        }
    }

    private func xPosition(for step: Int) -> CGFloat {
        let w = trackView.bounds.width
        if steps <= 1 { return trackView.frame.minX }
        let fraction = CGFloat(step) / CGFloat(steps - 1)
        return trackView.frame.minX + w * fraction
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        let location = gr.location(in: self)
        guard trackView.bounds.width > 0 else { return }
        let clampedX = max(trackView.frame.minX, min(location.x, trackView.frame.maxX))
        let relative = clampedX - trackView.frame.minX
        let step = Int(round(relative / stepWidth()))
        let clampedStep = max(0, min(step, steps - 1))
        if currentStep != clampedStep {
            currentStep = clampedStep
        }
    }

    // Expose an anchor to align the track across multiple rows
    var alignmentTrackLeadingAnchor: NSLayoutXAxisAnchor { trackView.leadingAnchor }
}
