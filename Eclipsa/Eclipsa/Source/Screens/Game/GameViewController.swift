//
//  NewGameViewController.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 16/09/25.
//

import UIKit
import SpriteKit
import GameplayKit

protocol GameScenePauseDelegate: AnyObject {
    func showPauseButton()
}

class GameViewController: UIViewController {
    
    let sceneManager: SceneManager
    let flowDelegate: FlowController
    
    var skView: SKView
    private var stopMusicObserver: NSObjectProtocol?
    
    init(flowDelegate: FlowController) {
        self.sceneManager = SceneManager(flowController: flowDelegate)
        self.skView = SKView()
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let pauseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Pause_Button"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(handlePause), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let pauseView: PauseView = {
        let view = PauseView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        stopMusicObserver = NotificationCenter.default.addObserver(forName: .stopBackgroundMusic, object: nil, queue: .main) { _ in
            // Fade out and stop background music immediately for end/win transitions
            AudioManager.shared.fadeOutBackgroundMusic(duration: 0.6, stopAfter: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        let scene = sceneManager.introScene(size: skView.bounds.size)
        scene.onFinished = { [weak self] in
            if let phaseOne = self?.sceneManager.phaseOne(){
                DispatchQueue.main.async {
                    phaseOne.pauseButtonDelegate = self
                    self?.skView.presentScene(phaseOne)
                    // Start in-game background music with lower volume, looping, and fade in
                    AudioManager.shared.playLoopingBackgroundMusic(named: "OST_InGame", crossfadeDuration: 3.0)
                }
            }
        }
        
        let transition = SKTransition.fade(withDuration: 0.4)
        skView.presentScene(scene, transition: transition)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let obs = stopMusicObserver {
            NotificationCenter.default.removeObserver(obs)
            stopMusicObserver = nil
        }
        // Fade out background music when leaving the game view
        AudioManager.shared.fadeOutBackgroundMusic(stopAfter: false)
    }
    
    deinit {
        if let obs = stopMusicObserver {
            NotificationCenter.default.removeObserver(obs)
            stopMusicObserver = nil
        }
    }
    
    func setupUI() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
        skView.addSubview(pauseButton)
        skView.addSubview(pauseView)
        skView.isMultipleTouchEnabled = true
//        setupDebugOptions()
        setupConstraints()
    }
    
    func setupConstraints(){
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pauseButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            pauseButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            pauseButton.heightAnchor.constraint(equalToConstant: 36),
            pauseButton.widthAnchor.constraint(equalToConstant: 36),
            
            pauseView.topAnchor.constraint(equalTo: view.topAnchor),
            pauseView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pauseView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            pauseView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
        ])
    }
    
    func setupDebugOptions(){
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
    }
    

    // MARK: - Orientation & Status Bar
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc
    private func handlePause(){
        guard var scene = skView.scene else { return }
        scene.isPaused.toggle()
        pauseView.handleHidePauseView()
        scene.isPaused ? WaveManager.shared.pauseWaveSystem() : WaveManager.shared.resumeWaveSystem()
    }
    
    @objc
    private func printDebug(){
        print("pressionei")
    }
}

extension GameViewController: GameScenePauseDelegate {
    func showPauseButton() {
        pauseButton.isHidden.toggle()
    }
}
