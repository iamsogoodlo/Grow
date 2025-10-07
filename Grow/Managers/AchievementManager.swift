import CoreData
import Foundation

class AchievementManager {
    static let shared = AchievementManager()
    
    func checkAchievements(gameManager: GameManager) -> [Achievement] {
        var unlocked: [Achievement] = []
        guard let profile = gameManager.profile else { return [] }
        
        let achievements = [
            ("first_habit", "First Steps", "Complete your first habit", "figure.walk", 1),
            ("level_5", "Novice", "Reach Level 5", "star.fill", 5),
            ("level_10", "Adept", "Reach Level 10", "star.circle.fill", 10),
            ("streak_7", "Week Warrior", "Maintain a 7-day streak", "flame.fill", 7),
            ("streak_30", "Month Master", "Maintain a 30-day streak", "flame.circle.fill", 30),
        ]
        
        for (key, name, desc, icon, target) in achievements {
            let userDefaultKey = "achievement_\(key)"
            let isEarned = UserDefaults.standard.bool(forKey: userDefaultKey)
            
            if isEarned { continue }
            
            var shouldUnlock = false
            
            switch key {
            case "first_habit":
                shouldUnlock = gameManager.todayLogs.contains { $0.completed }
            case "level_5":
                shouldUnlock = profile.level >= 5
            case "level_10":
                shouldUnlock = profile.level >= 10
            case "streak_7":
                shouldUnlock = gameManager.habits.contains { $0.currentStreak >= 7 }
            case "streak_30":
                shouldUnlock = gameManager.habits.contains { $0.currentStreak >= 30 }
            default:
                break
            }
            
            if shouldUnlock {
                UserDefaults.standard.set(true, forKey: userDefaultKey)
                let achievement = Achievement(
                    id: key,
                    key: key,
                    name: name,
                    description: desc,
                    icon: icon,
                    earnedAt: Date(),
                    progress: target,
                    target: target
                )
                unlocked.append(achievement)
            }
        }
        
        return unlocked
    }
}
