//
//  HomeScreen.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 08/09/25.
//

import UIKit
import SpriteKit

final class HomeView: UIView {
    
    var onPlayTapped: (() -> Void)?
    
    // Flag para configurar a neve apenas uma vez quando tivermos bounds válidos
    private var didSetupSnow = false
    
    // MARK: - Background
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Menu_Background"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // MARK: - Snow particles
    private let snowView: SKView = {
        let skView = SKView()
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.backgroundColor = .clear
        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true
        return skView
    }()
    
    private let container: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SunCro  n"
        titleLabel.textColor = .yellow
        if let displayFont = UIFont(name: "CCPixelArcade-Display", size: 64) {
            titleLabel.font = displayFont
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 64, weight: .heavy)
        }
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    private let playButton: UIButton = {
        let playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Tap to start", for: .normal)
        playButton.setTitleColor(.white, for: .normal)
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 20) {
            playButton.titleLabel?.font = joystickFont
        } else {
            playButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        }
        playButton.backgroundColor = .clear
        playButton.layer.cornerRadius = 0
        playButton.contentEdgeInsets = .zero
        playButton.addTarget(self, action: #selector(handlePlayTapped), for: .touchUpInside)
        return playButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        // Não chamar setupSnow aqui: bounds ainda são .zero
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        // Não chamar setupSnow aqui: bounds ainda são .zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Configure a cena quando o snowView já tiver tamanho válido
        if !didSetupSnow, snowView.bounds.size.width > 0, snowView.bounds.size.height > 0 {
            setupSnow()
            didSetupSnow = true
        }
    }
    
    private func setupUI() {
        backgroundColor = .black
        
        // Ordem de subviews: background -> partículas -> container
        addSubview(backgroundImageView)
        addSubview(snowView)
        addSubview(container)
        
        container.addSubview(titleLabel)
        container.addSubview(playButton)
        
        setupConstraints()
        
        startBlinkingPlayButton()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background ocupa toda a tela
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Snow view também ocupa toda a tela
            snowView.topAnchor.constraint(equalTo: topAnchor),
            snowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            snowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            snowView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Container centralizado
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            // Título no topo do container
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // Botão apenas texto, mais afastado do título
            playButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 48),
            playButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            playButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
    
    private func startBlinkingPlayButton() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0          // totalmente visível
        animation.toValue = 0.2            // quase transparente
        animation.duration = 1.0           // 1 segundo pra ir e voltar
        animation.autoreverses = true      // volta ao valor inicial
        animation.repeatCount = .infinity  // loop infinito
        playButton.layer.add(animation, forKey: "blink")
    }
    
    private func setupSnow() {
        // Use o tamanho do snowView (já com constraints aplicadas)
        let sceneSize = snowView.bounds.size
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        
        if let snowEmitter = SKEmitterNode(fileNamed: "SnowParticle.sks") {
            // Emitter no topo da cena, distribuído na largura
            snowEmitter.zPosition = 10
            snowEmitter.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height)
            snowEmitter.particlePositionRange = CGVector(dx: sceneSize.width, dy: 0)
            // Opcional: se quiser que as partículas “vivam” na cena
            snowEmitter.targetNode = scene
            scene.addChild(snowEmitter)
        }
        
        snowView.presentScene(scene)
    }
    
    @objc private func handlePlayTapped() {
        onPlayTapped?()
    }
}

