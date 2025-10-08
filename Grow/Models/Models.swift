import SwiftUI
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

