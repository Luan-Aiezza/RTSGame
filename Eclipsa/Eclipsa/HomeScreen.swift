//
//  HomeScreen.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 08/09/25.
//

import UIKit

final class HomeScreen: UIView {
    
    var onPlayTapped: (() -> Void)?
    
    private let container = UIView()
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupHierarchy()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupHierarchy()
        setupConstraints()
    }
    
    private func setupView() {
        backgroundColor = .black
        
        container.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SunCrown"
        titleLabel.textColor = .white
        // Use a variação "Display" (ajuste o PostScript name se necessário)
        if let displayFont = UIFont(name: "CCPixelArcade-Display", size: 48) {
            titleLabel.font = displayFont
        } else {
            // Fallback caso a fonte não esteja disponível
            titleLabel.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        }
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Play", for: .normal)
        playButton.setTitleColor(.black, for: .normal)
        // Use a variação "Joystick" (ajuste o PostScript name se necessário)
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 28) {
            playButton.titleLabel?.font = joystickFont
        } else {
            // Fallback caso a fonte não esteja disponível
            playButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        }
        playButton.backgroundColor = UIColor.systemYellow
        playButton.layer.cornerRadius = 14
        playButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 28, bottom: 14, right: 28)
        playButton.addTarget(self, action: #selector(handlePlayTapped), for: .touchUpInside)
    }
    
    private func setupHierarchy() {
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(playButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container centralizado e com margens seguras
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            // Título no topo do container
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // Botão abaixo do título
            playButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            playButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            playButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    @objc private func handlePlayTapped() {
        onPlayTapped?()
    }
}
