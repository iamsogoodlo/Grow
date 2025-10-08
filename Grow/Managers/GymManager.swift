import CoreData
import Foundation
import Combine

class GymManager: ObservableObject {
    let context: NSManagedObjectContext
    
    @Published var workouts: [Workout] = []
    @Published var personalRecords: [String: Double] = [:]
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    func loadData() {
        workouts = fetchWorkouts()
        personalRecords = calculatePRs()
    }
    
    // MARK: - Workout Management
    
    func createWorkout(title: String, sets: [(exercise: String, sets: Int, reps: Int, weight: Double, rpe: Int)]) -> Workout {
        let workout = Workout(context: context)
        workout.id = UUID()
        workout.date = Date()
        workout.title = title
        workout.duration = 0
        
        for (index, setData) in sets.enumerated() {
            let workoutSet = WorkoutSet(context: context)
            workoutSet.id = UUID()
            workoutSet.exercise = setData.exercise
            workoutSet.sets = Int16(setData.sets)
            workoutSet.reps = Int16(setData.reps)
            workoutSet.weight = setData.weight
            workoutSet.rpe = Int16(setData.rpe)
            workoutSet.orderIndex = Int16(index)
            workoutSet.workout = workout
        }
        
        saveContext()
        loadData()
        return workout
    }
    
    func finishWorkout(_ workout: Workout, duration: Int, gameManager: GameManager) {
        workout.duration = Int32(duration)
        
        // Calculate EXP based on duration and volume
        let volume = calculateWorkoutVolume(workout)
        let baseExp = min(duration / 2, 60)
        let volumeBonus = min(Int(volume / 1000), 40)
        let totalExp = baseExp + volumeBonus
        
        workout.expGranted = Int32(totalExp)
        
        // Grant EXP to player
        if let profile = gameManager.profile {
            profile.expCurrent += Int32(totalExp)
            
            while profile.expCurrent >= profile.expToNext {
                profile.expCurrent -= profile.expToNext
                profile.level += 1
                profile.expToNext = Int32(ScoringEngine.expForLevel(Int(profile.level)))
                gameManager.skillPoints += 1
                gameManager.showLevelUpModal = true
            }
        }
        
        // Check for PRs
        checkForPRs(workout, gameManager: gameManager)
        
        saveContext()
        loadData()
    }
    
    func deleteWorkout(_ workout: Workout) {
        context.delete(workout)
        saveContext()
        loadData()
    }
    
    // MARK: - PR Detection
    
    private func checkForPRs(_ workout: Workout, gameManager: GameManager) {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return }
        
        for set in sets {
            let exercise = set.exercise ?? ""
            let oneRM = calculate1RM(weight: set.weight, reps: Int(set.reps))
            
            if let currentPR = personalRecords[exercise] {
                if oneRM > currentPR {
                    personalRecords[exercise] = oneRM
                    
                    let badge = Badge(context: context)
                    badge.id = UUID()
                    badge.key = "pr_\(exercise.replacingOccurrences(of: " ", with: "_").lowercased())"
                    badge.earnedAt = Date()
                    
                    if let profile = gameManager.profile {
                        profile.expCurrent += 50
                    }
                }
            } else {
                personalRecords[exercise] = oneRM
            }
        }
    }
    
    private func calculate1RM(weight: Double, reps: Int) -> Double {
        return weight * (1 + Double(reps) / 30.0)
    }
    
    private func calculateWorkoutVolume(_ workout: Workout) -> Double {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return 0 }
        return sets.reduce(0.0) { total, set in
            total + (set.weight * Double(set.sets) * Double(set.reps))
        }
    }
    
    private func calculatePRs() -> [String: Double] {
        var prs: [String: Double] = [:]
        
        for workout in workouts {
            guard let sets = workout.sets as? Set<WorkoutSet> else { continue }
            
            for set in sets {
                let exercise = set.exercise ?? ""
                let oneRM = calculate1RM(weight: set.weight, reps: Int(set.reps))
                
                if let current = prs[exercise] {
                    prs[exercise] = max(current, oneRM)
                } else {
                    prs[exercise] = oneRM
                }
            }
        }
        
        return prs
    }
    
    private func fetchWorkouts() -> [Workout] {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 50
        return (try? context.fetch(request)) ?? []
    }
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
