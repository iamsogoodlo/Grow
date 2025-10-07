import SwiftUI
import CoreData

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

extension UserProfile: Identifiable {}
extension Habit: Identifiable {}
extension HabitLog: Identifiable {}
extension WeeklyQuest: Identifiable {}
extension Skill: Identifiable {}
extension Badge: Identifiable {}
extension Debuff: Identifiable {}
