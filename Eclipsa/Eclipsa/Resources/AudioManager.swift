
import Foundation
import AVFoundation

class AudioManager {
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
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
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
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
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
