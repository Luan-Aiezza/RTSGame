//
//  HomeScreen.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 08/09/25.
//

import UIKit
import SpriteKit

final class HomeView: UIView {
    
//    var onPlayTapped: (() -> Void)?
    weak var delegate: HomeViewDelegate?
    
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
    
    private let settingsButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.translatesAutoresizingMaskIntoConstraints = false
        let img = UIImage(named: "Config_Icon")?.withRenderingMode(.alwaysOriginal)
        bt.setImage(img, for: .normal)
        bt.widthAnchor.constraint(equalToConstant: 36).isActive = true
        bt.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return bt
    }()
    
    // MARK: - Game title (single asset)
    private let gameTitleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Menu_Game_Name"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        // Evita esticar demais dentro do container
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()
    
    private let playButton: UIButton = {
        let playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
//        playButton.setTitle("Tap to start", for: .normal)
        playButton.setTitle(NSLocalizedString("start", comment: ""), for: .normal)
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
    
    private let multiplayerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Multiplayer", for: .normal)
        button.setTitleColor(.white, for: .normal)
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 20) {
            button.titleLabel?.font = joystickFont
        } else {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        }
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(handleMultiplayerTapped), for: .touchUpInside)
        return button
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
        addSubview(settingsButton)
        settingsButton.addTarget(self, action: #selector(handleSettingsTapped), for: .touchUpInside)
        
        // Adiciona o título e o botão ao container
        container.addSubview(gameTitleImageView)
        container.addSubview(playButton)
        container.addSubview(multiplayerButton)
        
        setupConstraints()
        
        startBlinkingPlayButton()
        startPulsing(view: gameTitleImageView)              // título
        if let settingsIcon = settingsButton.imageView {    // ícone de configurações
            startPulsing(view: settingsIcon)
        }
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
            
            // Título (imagem) no topo do container
            gameTitleImageView.topAnchor.constraint(equalTo: container.topAnchor),
            gameTitleImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            gameTitleImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // Limite de altura para não extrapolar em telas menores (ajustável)
            gameTitleImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 240),
            
            // Botão um pouco deslocado para a esquerda e 24pt abaixo do título
            playButton.topAnchor.constraint(equalTo: gameTitleImageView.bottomAnchor, constant: 8),
            playButton.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: -8),
            //playButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            multiplayerButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 16),
            multiplayerButton.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: -8),
            multiplayerButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            // Settings button at top-right
            settingsButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
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
    
    private func startPulsing(view: UIView,
                              from: CGFloat = 1.0,
                              to: CGFloat = 1.20,
                              duration: CFTimeInterval = 1.2) {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = from
        pulse.toValue = to
        pulse.duration = duration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(pulse, forKey: "pulse")
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
        delegate?.didTapPlayButton()
    }
    
    @objc private func handleSettingsTapped() {
        delegate?.didTapConfigurationButton()
    }
    
    @objc private func handleMultiplayerTapped() {
        delegate?.didTapMultiplayerButton()
        print("cliquei no multiplayer")
    }
}

