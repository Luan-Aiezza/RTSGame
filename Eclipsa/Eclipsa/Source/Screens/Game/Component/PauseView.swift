//
//  ContinueView.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 26/09/25.
//

import UIKit

protocol PauseViewDelegate: AnyObject {
    func pauseViewDidTapContinue()
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
        label.textColor = .white
        label.isUserInteractionEnabled = true
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        startPulseAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .black.withAlphaComponent(0.6)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        continueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(continueLabel)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapPause))
        continueLabel.addGestureRecognizer(gesture)
        
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
        ])
    }
    
    func handleHidePauseView() {
        DispatchQueue.main.async {
            self.isHidden.toggle()
        }
    }
    
    private func startPulseAnimation() {
        UIView.animate(withDuration: 0.8,
                       delay: 0,
                       options: [.repeat, .autoreverse, .allowUserInteraction],
                       animations: {
            self.continueLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.continueLabel.alpha = 0.6
        }, completion: { _ in
            self.continueLabel.transform = .identity
            self.continueLabel.alpha = 1.0
        })
    }
    
    @objc
    private func tapPause(){
        delegate?.pauseViewDidTapContinue()
    }
}
