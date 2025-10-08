import Foundation

enum ExperienceSource: String, Codable, CaseIterable {
    case habit
    case habitPenalty
    case workout
    case personalRecord
    case nutrition
    case weight
    case barcode
    case manual
}

struct ExperienceEvent: Identifiable, Codable {
    let id = UUID()
    let amount: Int
    let source: ExperienceSource
    let reason: String
    let metadata: [String: String]
    let timestamp: Date
}
