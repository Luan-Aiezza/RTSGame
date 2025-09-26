//
//  ContinueView.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 26/09/25.
//

import UIKit

class PauseView: UIView {
    
    private let continueLabel: UILabel = {
        let label = UILabel()
        label.text = "Continue"
        label.font = UIFont(name: "CCPixelArcade-Joystick", size: 50)
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        continueLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .black.withAlphaComponent(0.4)
        addSubview(continueLabel)
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            continueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            continueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    func handleHidePauseView() {
        DispatchQueue.main.async{
            self.isHidden.toggle()
        }
    }
    
}
