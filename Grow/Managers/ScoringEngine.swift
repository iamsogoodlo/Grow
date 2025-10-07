import Foundation

class ScoringEngine {
    static func calculateExpGain(
        habit: Habit,
        actualValue: Double,
        streak: Int,
        totalDailiesCompleted: Int,
        activeSkills: [Skill],
        permMultiplier: Double,
        completedBeforeTenAm: Bool,
        completedAfterEightPm: Bool,
        isPerfectDay: Bool,
        topTwoHabits: [UUID]
    ) -> Int {
        let baseExp = Double(habit.baseExp)
        
        var quantityRatio = 1.0
        if habit.scalar == ScalarType.quantity.rawValue {
            quantityRatio = min(actualValue / habit.targetNumber, 1.3)
        }
        
        let streakBonus = 1.0 + 0.05 * Double(streak / 3)
        let streakMult = min(streakBonus, 1.5)
        
        let comboMult = totalDailiesCompleted >= 4 ? 1.05 : 1.0
        
        var skillMult = 1.0
        
        if completedBeforeTenAm && activeSkills.contains(where: { $0.key == SkillKey.earlyBird.rawValue }) {
            skillMult *= 1.10
        }
        
        if completedAfterEightPm && activeSkills.contains(where: { $0.key == SkillKey.nightOwl.rawValue }) {
            skillMult *= 1.10
        }
        
        if let habitId = habit.id, topTwoHabits.contains(habitId),
           activeSkills.contains(where: { $0.key == SkillKey.specialist.rawValue }) {
            skillMult *= 1.10
        }
        
        if isPerfectDay && activeSkills.contains(where: { $0.key == SkillKey.perfectionist.rawValue }) {
            skillMult *= 1.15
        }
        
        let permMult = 1.0 + permMultiplier
        let totalExp = baseExp * quantityRatio * streakMult * comboMult * skillMult * permMult
        return Int(totalExp.rounded())
    }
    
    static func calculatePenalty(baseExp: Int, hasIronWillActive: Bool, ironWillUsesLeft: Int) -> Int {
        let penaltyBase = Double(baseExp) * 0.6
        let penaltyMult = (hasIronWillActive && ironWillUsesLeft > 0) ? 0.8 : 1.0
        return Int((penaltyBase * penaltyMult).rounded())
    }
    
    static func expForLevel(_ level: Int) -> Int {
        return Int((200.0 * pow(1.25, Double(level - 1))).rounded())
    }
}
