import Foundation
import SpriteKit
import AVFoundation

class AudioManager {
    private let supportedExtensions = ["mp3", "wav"]
    static let shared = AudioManager()
    private static let defaults = UserDefaults.standard
    private static let keyBGMVolume = "audio.bgmVolume"
    private static let keySFXVolume = "audio.sfxVolume"

    private var audioPlayers: [String: [AVAudioPlayer]] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let maxSimultaneousPlays = 3
    private var sfxVolume: Float = 1.0 {
        didSet {
            updateAllVolumes()
            Self.defaults.set(sfxVolume, forKey: Self.keySFXVolume)
        }
    }
    private var bgmVolume: Float = 1.0 {
        didSet {
            updateAllVolumes()
            Self.defaults.set(bgmVolume, forKey: Self.keyBGMVolume)
        }
    }

    // MARK: - Public step-based volume interface (1..10 -> 0.1..1.0)
    var musicVolumeStep: Int {
        get { Self.step(from: bgmVolume) }
        set { setBackgroundMusicVolume(Self.volume(fromStep: newValue)) }
    }

    var effectsVolumeStep: Int {
        get { Self.step(from: sfxVolume) }
        set { setEffectsVolume(Self.volume(fromStep: newValue)) }
    }

    // Converts a step in 1...10 to a volume 0.1...1.0 (clamped)
    static func volume(fromStep step: Int) -> Float {
        let clamped = max(1, min(step, 10))
        return Float(clamped) / 10.0
    }

    // Converts a volume 0.0...1.0 to nearest step 1...10 (0 treated as 1)
    static func step(from volume: Float) -> Int {
        let clamped = max(0.0, min(volume, 1.0))
        let step = Int(round(clamped * 10.0))
        return max(1, min(step, 10))
    }

    private init() {
        // Load persisted volumes, defaulting to 1.0
        let savedBGM = Self.defaults.object(forKey: Self.keyBGMVolume) as? Float
        let savedSFX = Self.defaults.object(forKey: Self.keySFXVolume) as? Float
        if let v = savedBGM { bgmVolume = max(0.0, min(v, 1.0)) }
        if let v = savedSFX { sfxVolume = max(0.0, min(v, 1.0)) }
    }

    // MARK: - Fades para Música de Background
    func fadeInBackgroundMusic(named name: String, duration: TimeInterval = 6.0) {
        // Começa com volume 0 e aumenta até o volume global
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: name, withExtension: $0) }).first else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer = player
            player.numberOfLoops = -1
            let target = bgmVolume
            player.volume = 0.0
            player.prepareToPlay()
            player.play()
            guard duration > 0 else {
                player.volume = target
                return
            }
            let steps = 60
            let stepDuration = duration / Double(steps)
            for i in 1...steps {
                let delay = stepDuration * Double(i)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self = self, let p = self.backgroundMusicPlayer else { return }
                    let progress = Float(i) / Float(steps)
                    p.volume = min(target, progress * target)
                }
            }
        } catch {
            print("")
        }
    }

    
    private var fadeSessionID = UUID()
    
    func fadeOutBackgroundMusic(duration: TimeInterval = 3.0, stopAfter: Bool = true) {
        guard let player = backgroundMusicPlayer else { return }
        let sessionID = UUID()
        fadeSessionID = sessionID
        
        let startVolume = player.volume
        guard duration > 0 else {
            player.volume = 0
            if stopAfter { stopBackgroundMusic() }
            return
        }
        let steps = 60
        let stepDuration = duration / Double(steps)
        for i in 1...steps {
            let delay = stepDuration * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self,
                      let p = self.backgroundMusicPlayer,
                      self.fadeSessionID == sessionID else { return } // cancela fade antigo
                let progress = Float(i) / Float(steps)
                p.volume = max(0, startVolume * (1 - progress))
                if i == steps, stopAfter {
                    self.stopBackgroundMusic()
                }
            }
        }
    }

    // MARK: - Efeitos Sonoros
    func playSound(named name: String) {
        if let players = audioPlayers[name] {
            if let availablePlayer = players.first(where: { !$0.isPlaying }) {
                availablePlayer.volume = sfxVolume
                availablePlayer.play()
                return
            }

            if players.count < maxSimultaneousPlays {
                if let player = createPlayer(for: name) {
                    player.volume = sfxVolume
                    audioPlayers[name]?.append(player)
                    player.play()
                }
            }
        } else {
            if let player = createPlayer(for: name) {
                player.volume = sfxVolume
                audioPlayers[name] = [player]
                player.play()
            }
        }
    }

    // MARK: - Musica de Background
    func playBackgroundMusic(named name: String) {
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: name, withExtension: $0) }).first else {
            return
        }

        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // loop infinito
            backgroundMusicPlayer?.volume = bgmVolume
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
        } catch {
            print("")
        }
    }

    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }

    // MARK: - Controle de Volume

    /// Sets the volume for background music only. Value range: 0.0 to 1.0.
    func setVolume(to value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        bgmVolume = clamped
    }

    func setBackgroundMusicVolume(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        bgmVolume = clamped
    }

    func setEffectsVolume(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        sfxVolume = clamped
    }

    private func updateAllVolumes() {
        for (_, players) in audioPlayers {
            for player in players {
                player.volume = sfxVolume
            }
        }
        backgroundMusicPlayer?.volume = bgmVolume
    }

    // MARK: - Internal
    private func createPlayer(for name: String) -> AVAudioPlayer? {
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: name, withExtension: $0) }).first else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("")
            return nil
        }
    }
}

extension AudioManager {
    func playSoundIfVisible(named name: String, from node: SKNode) {
        guard let scene = node.scene,
              let camera = scene.camera,
              camera.isNodeVisible(node, in: scene) else { return }
        playSound(named: name)
    }
}

/////Como usar!
//// Som de efeito
//AudioManager.shared.playSound(named: "swipe")
//
//// Música de fundo
//AudioManager.shared.playBackgroundMusic(named: "main_theme")
//
//// Parar música de fundo
//AudioManager.shared.stopBackgroundMusic()
//
//// Alterar volume global (0.0 a 1.0)
//AudioManager.shared.setVolume(to: 0.3)
