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
    let id: UUID
    let amount: Int
    let source: ExperienceSource
    let reason: String
    let metadata: [String: String]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        amount: Int,
        source: ExperienceSource,
        reason: String,
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.source = source
        self.reason = reason
        self.metadata = metadata
        self.timestamp = timestamp
    }
}
