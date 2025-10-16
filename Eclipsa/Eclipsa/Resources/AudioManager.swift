import Foundation
import SpriteKit
import AVFoundation

extension AudioManager {
    func playSoundIfVisible(named name: String, from node: SKNode) {
        guard let scene = node.scene,
              let camera = scene.camera,
              camera.isNodeVisible(node, in: scene) else { return }
        playSound(named: name)
    }
}

extension AudioManager {
    
    /// Reproduz música de fundo em loop contínuo com crossfade entre cada repetição.
    func playLoopingBackgroundMusic(named name: String, crossfadeDuration: TimeInterval = 2.0) {
        startBackgroundMusic(named: name, crossfadeDuration: crossfadeDuration)
    }
    
    private func startBackgroundMusic(named name: String, crossfadeDuration: TimeInterval) {
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: name, withExtension: $0) }).first else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = bgmVolume
            player.prepareToPlay()
            player.play()
            backgroundMusicPlayer = player
            
            // Agenda crossfade antes do fim
            let delay = player.duration - crossfadeDuration
            if delay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.crossfadeBackgroundMusic(named: name, duration: crossfadeDuration)
                }
            }
            
        } catch {
            print("Erro ao carregar música \(name): \(error)")
        }
    }
    
    private func crossfadeBackgroundMusic(named name: String, duration: TimeInterval) {
        guard let oldPlayer = backgroundMusicPlayer else { return }
        guard let url = supportedExtensions.compactMap({ Bundle.main.url(forResource: name, withExtension: $0) }).first else { return }
        
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.volume = 0.0
            newPlayer.prepareToPlay()
            newPlayer.play()
            
            // registra os dois no array de ativos
            crossfadePlayers = [oldPlayer, newPlayer]
            
            backgroundMusicPlayer = newPlayer
            
            let steps = 60
            let stepDuration = duration / Double(steps)
            for i in 0...steps {
                let delay = stepDuration * Double(i)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    let progress = Float(i) / Float(steps)
                    oldPlayer.volume = self.bgmVolume * (1 - progress)
                    newPlayer.volume = self.bgmVolume * progress
                    if i == steps {
                        oldPlayer.stop()
                        self.crossfadePlayers = [newPlayer] // só o novo fica ativo
                    }
                }
            }
            
            // agenda próximo crossfade
            let delay = newPlayer.duration - duration
            if delay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.crossfadeBackgroundMusic(named: name, duration: duration)
                }
            }
            
        } catch {
            print("Erro ao preparar crossfade: \(error)")
        }
    }

}

class AudioManager {
    
    private var fadeSessionID = UUID()
    private var crossfadePlayers: [AVAudioPlayer] = []
    private let supportedExtensions = ["mp3", "wav"]
    
    static let shared = AudioManager()
    
    // MARK: - UserDefaults Keys (NOVA CHAVE ADICIONADA)
    private static let defaults = UserDefaults.standard
    private static let keyBGMVolume = "audio.bgmVolume"
    private static let keySFXVolume = "audio.sfxVolume"
    private static let keyVoiceVolume = "audio.voiceVolume" // <-- ADICIONADO

    // MARK: - Audio Players (NOVO DICIONÁRIO ADICIONADO)
    private var audioPlayers: [String: [AVAudioPlayer]] = [:] // Para SFX
    private var voiceAudioPlayers: [String: [AVAudioPlayer]] = [:] // <-- ADICIONADO para Vozes
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let maxSimultaneousPlays = 3
    
    // MARK: - Volume Properties (NOVA PROPRIEDADE ADICIONADA)
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
    
    // ADICIONADO: Propriedade de volume para a voz 🎙️
    private var voiceVolume: Float = 1.0 {
        didSet {
            updateAllVolumes()
            Self.defaults.set(voiceVolume, forKey: Self.keyVoiceVolume)
        }
    }

    // MARK: - Public step-based volume interface (NOVA INTERFACE ADICIONADA)
    var musicVolumeStep: Int {
        get { Self.step(from: bgmVolume) }
        set { setBackgroundMusicVolume(Self.volume(fromStep: newValue)) }
    }

    var effectsVolumeStep: Int {
        get { Self.step(from: sfxVolume) }
        set { setEffectsVolume(Self.volume(fromStep: newValue)) }
    }
    
    // ADICIONADO: Interface de volume para a voz
    var voiceVolumeStep: Int {
        get { Self.step(from: voiceVolume) }
        set { setVoiceVolume(Self.volume(fromStep: newValue)) }
    }

    // ... (funções static volume e step permanecem iguais) ...
    static func volume(fromStep step: Int) -> Float {
        let clamped = max(1, min(step, 10))
        return Float(clamped) / 10.0
    }
    static func step(from volume: Float) -> Int {
        let clamped = max(0.0, min(volume, 1.0))
        let step = Int(round(clamped * 10.0))
        return max(1, min(step, 10))
    }

    // MARK: - Init (MODIFICADO)
    private init() {
        // Load persisted volumes, defaulting to 1.0
        let savedBGM = Self.defaults.object(forKey: Self.keyBGMVolume) as? Float
        let savedSFX = Self.defaults.object(forKey: Self.keySFXVolume) as? Float
        let savedVoice = Self.defaults.object(forKey: Self.keyVoiceVolume) as? Float // <-- ADICIONADO
        
        if let v = savedBGM { bgmVolume = max(0.0, min(v, 1.0)) }
        if let v = savedSFX { sfxVolume = max(0.0, min(v, 1.0)) }
        if let v = savedVoice { voiceVolume = max(0.0, min(v, 1.0)) } // <-- ADICIONADO
        
        setVoiceVolume(0.1)
    }

    // MARK: - Fades para Música de Background
    func fadeInBackgroundMusic(named name: String, duration: TimeInterval = 3.0) {
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
    
    func fadeOutBackgroundMusic(duration: TimeInterval = 1.0, stopAfter: Bool = true) {
           let sessionID = UUID()
           fadeSessionID = sessionID
           
           // pega snapshot dos players ativos
           let players = [backgroundMusicPlayer].compactMap { $0 } + crossfadePlayers
           guard !players.isEmpty else { return }
           
           let startVolumes = players.map { $0.volume }
           let steps = max(1, 60)
           let stepDuration = duration / Double(steps)
           
           for i in 0...steps {
               let delay = stepDuration * Double(i)
               DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                   guard let self, self.fadeSessionID == sessionID else { return }
                   let progress = Float(i) / Float(steps)
                   for (idx, player) in players.enumerated() {
                       player.volume = max(0, startVolumes[idx] * (1 - progress))
                   }
                   if i == steps, stopAfter {
                       for player in players {
                           player.stop()
                       }
                       self.backgroundMusicPlayer = nil
                       self.crossfadePlayers.removeAll()
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

    // MARK: - Vozes (NOVA SEÇÃO ADICIONADA) 🎙️
    func playVoice(named name: String) {
        // Esta função é uma cópia da playSound, mas adaptada para o canal de voz
        if let players = voiceAudioPlayers[name] {
            if let availablePlayer = players.first(where: { !$0.isPlaying }) {
                availablePlayer.volume = voiceVolume // Usa o volume de voz
                availablePlayer.play()
                return
            }

            if players.count < maxSimultaneousPlays {
                if let player = createPlayer(for: name) {
                    player.volume = voiceVolume // Usa o volume de voz
                    voiceAudioPlayers[name]?.append(player)
                    player.play()
                }
            }
        } else {
            if let player = createPlayer(for: name) {
                player.volume = voiceVolume // Usa o volume de voz
                voiceAudioPlayers[name] = [player]
                player.play()
            }
        }
    }
    
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

    // ... (suas funções de Musica de Background permanecem iguais) ...

    // MARK: - Controle de Volume (NOVA FUNÇÃO ADICIONADA E UMA MODIFICADA)
    
    func setBackgroundMusicVolume(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        bgmVolume = clamped
    }
    
    func setEffectsVolume(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        sfxVolume = clamped
    }
    
    // ADICIONADO: Setter para o volume da voz
    func setVoiceVolume(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        voiceVolume = clamped
    }
    
    // MODIFICADO: Agora atualiza os players de voz também
    private func updateAllVolumes() {
        // Atualiza SFX
        for (_, players) in audioPlayers {
            for player in players {
                player.volume = sfxVolume
            }
        }
        
        // ADICIONADO: Atualiza Vozes
        for (_, players) in voiceAudioPlayers {
            for player in players {
                player.volume = voiceVolume
            }
        }
        
        // Atualiza BGM
        backgroundMusicPlayer?.volume = bgmVolume
    }
    
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
