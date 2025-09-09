//
//  HomeScreen.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 08/09/25.
//

import UIKit

final class HomeView: UIView {
    
    var onPlayTapped: (() -> Void)?
    
    private let container: UIView = {
        let container = UIView()
        
        container.translatesAutoresizingMaskIntoConstraints = false
        
        return container
        
    }()
    
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SunCrown"
        titleLabel.textColor = .white
        if let displayFont = UIFont(name: "CCPixelArcade-Display", size: 48) {
            titleLabel.font = displayFont
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        }
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    private let playButton: UIButton = {
        let playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Play", for: .normal)
        playButton.setTitleColor(.black, for: .normal)
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 28) {
            playButton.titleLabel?.font = joystickFont
        } else {
            playButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        }
        playButton.backgroundColor = UIColor.systemYellow
        playButton.layer.cornerRadius = 14
        playButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 28, bottom: 14, right: 28)
        playButton.addTarget(self, action: #selector(handlePlayTapped), for: .touchUpInside)
        return playButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .black
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(playButton)
        setupConstraints()
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
