//
//  AchievementManager.swift
//  Eclipsa
//
//  Created by Joseph Pereira on 09/10/25.
//
import Foundation

protocol Achievement {
    var identifier: String { get }
    var title: String { get }
    func checkCondition(with stats: GameStats) -> Bool
    func progressPercentage(with stats: GameStats) -> Double
}

final class AchievementManager {
    static let shared = AchievementManager()
    
    private var gameStats = GameStats()
    private var unlockedAchievements: Set<String> = []
    private var achievements: [Achievement] = []
    
    private init() {
        loadProgress()
        registerAchievements()
    }
    
    // MARK: - Registration
    
    private func registerAchievements() {
        achievements = [
            TroopCreationAchievement(identifier: "gameplay001", title: "Summoned 50 troops", requiredQuantity: 50),
            TroopCreationAchievement(identifier: "gameplay002", title: "Summoned 100 troops", requiredQuantity: 100),
            TroopCreationAchievement(identifier: "gameplay003", title: "Summoned 150 troops", requiredQuantity: 150),
        ]
    }
    
    // MARK: - Public Methods
    
    func recordRangedCreation() {
        gameStats.totalRangedCreated += 1
        saveProgress()
        checkAchievements()
        
    }
    
    func recordMeleeCreation() {
        gameStats.totalMeleeCreated += 1
        saveProgress()
        checkAchievements()
    }
    
    // MARK: - Achievement Logic
    
    private func checkAchievements() {
        for achievement in achievements {
            guard !unlockedAchievements.contains(achievement.identifier) else { continue }
            
            if achievement.checkCondition(with: gameStats) {
                unlockAchievement(achievement)
            }
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        print("🎉 Achievement unlocked: \(achievement.title)")
        unlockedAchievements.insert(achievement.identifier)
        saveProgress()
        GameCenterManager.shared.reportAchievement(identifier: achievement.identifier)
    }
    
    // MARK: - Progress Tracking
    
    func getProgress(for identifier: String) -> Double? {
        return achievements.first { $0.identifier == identifier }?
            .progressPercentage(with: gameStats)
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        let encoder = JSONEncoder()
        if let statsData = try? encoder.encode(gameStats),
           let achievementsData = try? encoder.encode(Array(unlockedAchievements)) {
            UserDefaults.standard.set(statsData, forKey: "GameStats")
            UserDefaults.standard.set(achievementsData, forKey: "UnlockedAchievements")
        }
    }
    
    private func loadProgress() {
        let decoder = JSONDecoder()
        
        if let statsData = UserDefaults.standard.data(forKey: "GameStats"),
           let stats = try? decoder.decode(GameStats.self, from: statsData) {
            gameStats = stats
        }
        
        if let achievementsData = UserDefaults.standard.data(forKey: "UnlockedAchievements"),
           let achievements = try? decoder.decode([String].self, from: achievementsData) {
            unlockedAchievements = Set(achievements)
        }
    }
}

struct GameStats: Codable {
    static let currentVersion = 1
    
    var version: Int = currentVersion
    var totalRangedCreated: Int = 0
    var totalMeleeCreated: Int = 0
    var totalPortalDestroyed: Int = 0
//    var totalBossesDefeated: Int = 0      // Adicionado na v2
//    var totalDeaths: Int = 0              // Adicionado na v3
//    var highestCombo: Int = 0             // Adicionado na v3
    
    enum CodingKeys: String, CodingKey {
        case version
        case totalRangedCreated
        case totalMeleeCreated
        case totalPortalDestroyed
//        case totalBossesDefeated
//        case totalDeaths
//        case highestCombo
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let loadedVersion = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        version = Self.currentVersion
        
        totalRangedCreated = try container.decodeIfPresent(Int.self, forKey: .totalRangedCreated) ?? totalRangedCreated
        totalMeleeCreated = try container.decodeIfPresent(Int.self, forKey: .totalMeleeCreated) ?? totalMeleeCreated
        totalPortalDestroyed = try container.decodeIfPresent(Int.self, forKey: .totalPortalDestroyed) ?? totalPortalDestroyed
        
//        totalBossesDefeated = try container.decodeIfPresent(Int.self, forKey: .totalBossesDefeated) ?? totalBossesDefeated
//        totalDeaths = try container.decodeIfPresent(Int.self, forKey: .totalDeaths) ?? totalDeaths
//        highestCombo = try container.decodeIfPresent(Int.self, forKey: .highestCombo) ?? highestCombo
        
        if loadedVersion < Self.currentVersion {
            logMigration(from: loadedVersion)
        }
    }
    
    private func logMigration(from oldVersion: Int) {
        let migratedFields = (oldVersion..<Self.currentVersion).flatMap { v -> [String] in
            switch v {
            case 1: return []
            case 2: return ["totalDeaths", "highestCombo"]
            default: return []
            }
        }
        
        if !migratedFields.isEmpty {
            print("Migrated GameStats from v\(oldVersion) to v\(Self.currentVersion)")
            print("New fields initialized: \(migratedFields.joined(separator: ", "))")
        }
    }
}

struct TroopCreationAchievement: Achievement {
    let identifier: String
    let title: String
    let requiredQuantity: Int
    
    func checkCondition(with stats: GameStats) -> Bool {
        print("Melee: \(stats.totalMeleeCreated)")
        print("Ranged: \(stats.totalRangedCreated)")
        let quantity = stats.totalMeleeCreated + stats.totalRangedCreated
        return quantity >= requiredQuantity
    }
    
    func progressPercentage(with stats: GameStats) -> Double {
        let quantity = stats.totalMeleeCreated + stats.totalRangedCreated
        return min(Double(quantity) / Double(requiredQuantity), 1.0)
    }
    
}
