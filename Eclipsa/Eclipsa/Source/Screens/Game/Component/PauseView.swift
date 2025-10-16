//
//  ContinueView.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 26/09/25.
//

import UIKit

protocol PauseViewDelegate: AnyObject {
    func pauseViewDidTapContinue()
    func didTapExit()
}

class PauseView: UIView {
    
    weak var delegate: PauseViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "PAUSE"
        label.font = UIFont(name: "CCPixelArcade-Display", size: 50)
        label.textColor = .systemYellow
        return label
    }()
    
    private let continueLabel: UILabel = {
        let label = UILabel()
        label.text = "Continue"
        label.font = UIFont(name: "CCPixelArcade-Joystick", size: 24)
        label.textColor = .systemGreen
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let exitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Exit", for: .normal)
        button.titleLabel?.font = UIFont(name: "CCPixelArcade-Joystick", size: 24)
        button.setTitleColor(.systemRed, for: .normal)
        button.tintColor = .white
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        startPulseAnimations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .black.withAlphaComponent(0.6)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        continueLabel.translatesAutoresizingMaskIntoConstraints = false
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(continueLabel)
        addSubview(exitButton)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapPause))
        continueLabel.addGestureRecognizer(gesture)
        
        exitButton.addTarget(self, action: #selector(tapExit), for: .touchUpInside)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Centraliza o título no topo
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: continueLabel.topAnchor, constant: -40),
            
            // Centraliza o botão Continue
            continueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            continueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Botão Exit logo abaixo
            exitButton.centerXAnchor.constraint(equalTo: continueLabel.centerXAnchor),
            exitButton.topAnchor.constraint(equalTo: continueLabel.bottomAnchor, constant: 20)
        ])
    }
    
    func handleHidePauseView() {
        DispatchQueue.main.async {
            self.isHidden.toggle()
        }
    }
    
    private func startPulseAnimations() {
        // Continue pulsando
        pulse(view: continueLabel, duration: 0.8, delay: 0)
        // Exit pulsando com um pequeno delay para dar contraste
        pulse(view: exitButton, duration: 0.8, delay: 0.4)
    }
    
    private func pulse(view: UIView, duration: TimeInterval, delay: TimeInterval) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: [.repeat, .autoreverse, .allowUserInteraction],
                       animations: {
            view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            view.alpha = 0.6
        }, completion: { _ in
            view.transform = .identity
            view.alpha = 1.0
        })
    }
    
    @objc
    private func tapPause() {
        delegate?.pauseViewDidTapContinue()
    }
    
    @objc
    private func tapExit() {
        delegate?.didTapExit()
    }
}
