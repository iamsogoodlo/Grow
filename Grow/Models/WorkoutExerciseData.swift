import Foundation

struct WorkoutExerciseData: Codable, Equatable {
    var name: String
    var sets: Int?
    var reps: Int?
    var weight: Double?
    var notes: String?
}
