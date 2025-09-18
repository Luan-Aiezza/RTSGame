import Foundation
import AVFoundation

class AudioManager {
    private let supportedExtensions = ["mp3", "wav"]
    static let shared = AudioManager()

    private var audioPlayers: [String: [AVAudioPlayer]] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let maxSimultaneousPlays = 3
    private var globalVolume: Float = 1.0 {
        didSet {
            updateAllVolumes()
        }
    }

    private init() {}

    // MARK: - Fades para Música de Background
    func fadeInBackgroundMusic(named name: String, duration: TimeInterval = 6.0) {
        // Começa com volume 0 e aumenta até o volume global
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: name, withExtension: $0) }).first else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer = player
            player.numberOfLoops = -1
            let target = globalVolume
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

    func fadeOutBackgroundMusic(duration: TimeInterval = 3.0, stopAfter: Bool = true) {
        guard let player = backgroundMusicPlayer else { return }
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
                guard let self = self, let p = self.backgroundMusicPlayer else { return }
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
                availablePlayer.volume = globalVolume
                availablePlayer.play()
                return
            }

            if players.count < maxSimultaneousPlays {
                if let player = createPlayer(for: name) {
                    player.volume = globalVolume
                    audioPlayers[name]?.append(player)
                    player.play()
                }
            }
        } else {
            if let player = createPlayer(for: name) {
                player.volume = globalVolume
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
            backgroundMusicPlayer?.volume = globalVolume
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
    func setVolume(to value: Float) {
        globalVolume = min(max(value, 0.0), 1.0) // Clamp entre 0.0 e 1.0
    }

    private func updateAllVolumes() {
        for (_, players) in audioPlayers {
            for player in players {
                player.volume = globalVolume
            }
        }
        backgroundMusicPlayer?.volume = globalVolume
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
