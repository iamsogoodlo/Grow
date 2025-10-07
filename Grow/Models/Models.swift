import SwiftUI
import CoreData
import Foundation

enum HabitType: String, Codable, CaseIterable {
    case daily, weekly
}

enum HabitMode: String, Codable {
    case good, bad
}

enum ScalarType: String, Codable {
    case binary, quantity
}

enum PlayerClass: String, Codable, CaseIterable {
    case warrior = "Warrior"
    case scholar = "Scholar"
    case monk = "Monk"
    
    var emoji: String {
        switch self {
        case .warrior: return "⚔️"
        case .scholar: return "📚"
        case .monk: return "🧘"
        }
    }
    
    var color: Color {
        switch self {
        case .warrior: return .red
        case .scholar: return .blue
        case .monk: return .green
        }
    }
}

enum SkillKey: String, Codable, CaseIterable {
    case earlyBird = "early_bird"
    case specialist = "specialist"
    case ironWill = "iron_will"
    case nightOwl = "night_owl"
    case perfectionist = "perfectionist"
    case resilient = "resilient"

    var name: String {
        switch self {
        case .earlyBird: return "Early Bird"
        case .specialist: return "Specialist"
        case .ironWill: return "Iron Will"
        case .nightOwl: return "Night Owl"
        case .perfectionist: return "Perfectionist"
        case .resilient: return "Resilient"
        }
    }

    var description: String {
        switch self {
        case .earlyBird: return "+10% EXP before 10am"
        case .specialist: return "+10% EXP on top 2 habits"
        case .ironWill: return "-20% penalty 2×/week"
        case .nightOwl: return "+10% EXP after 8pm"
        case .perfectionist: return "+15% EXP on perfect days"
        case .resilient: return "Streak shield recharges faster"
        }
    }

    var tier: Int {
        switch self {
        case .earlyBird, .specialist, .ironWill:
            return 1
        case .nightOwl, .perfectionist, .resilient:
            return 2
        }
    }

    var icon: String {
        switch self {
        case .earlyBird: return "sunrise.fill"
        case .specialist: return "star.fill"
        case .ironWill: return "shield.fill"
        case .nightOwl: return "moon.stars.fill"
        case .perfectionist: return "sparkles"
        case .resilient: return "heart.fill"
        }
    }
}

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let displayName: String
    let playerClass: String
    let level: Int
    let totalExp: Int
    let weeklyExp: Int
    let bestStreak: Int
    let updatedAt: Date
    var rank: Int = 0
}

struct Achievement: Codable, Identifiable {
    let id: String
    let key: String
    let name: String
    let description: String
    let icon: String
    let earnedAt: Date?
    let progress: Int
    let target: Int

    var isUnlocked: Bool { progress >= target }
}

extension UserProfile: Identifiable {}
extension Habit: Identifiable {}
extension HabitLog: Identifiable {}
extension WeeklyQuest: Identifiable {}
extension Skill: Identifiable {}
extension Badge: Identifiable {}
extension Debuff: Identifiable {}
