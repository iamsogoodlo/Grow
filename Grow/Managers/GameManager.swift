import SwiftUI
import Combine
import CoreData
#if os(iOS)
import UIKit
#endif

class GameManager: ObservableObject {
    let context: NSManagedObjectContext
    @Published var profile: UserProfile?
    @Published var habits: [Habit] = []
    @Published var todayLogs: [HabitLog] = []
    @Published var activeDebuffs: [Debuff] = []
    @Published var weeklyQuest: WeeklyQuest?
    @Published var skills: [Skill] = []
    
    @Published var showLevelUpModal = false
    @Published var showChestModal = false
    @Published var showAchievementModal = false
    @Published var showUndoSnackbar = false
    @Published var lastAction: (() -> Void)?
    @Published var lastAchievement: UnlockedAchievement?
    @Published var skillPoints = 0
    @Published var ironWillUsesThisWeek = 0

    private enum HapticEvent {
        case success
        case warning
        case error
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    func loadData() {
        profile = fetchUserProfile()
        habits = fetchActiveHabits()
        todayLogs = fetchTodayLogs()
        activeDebuffs = fetchActiveDebuffs()
        weeklyQuest = fetchCurrentWeeklyQuest()
        skills = fetchSkills()
    }
    
    func completeHabit(habit: Habit, value: Double = 1.0) {
        let log = HabitLog(context: context)
        log.id = UUID()
        log.date = Date()
        log.valueNumber = value
        log.completed = true
        log.habit = habit
        
        let streak = Int(habit.currentStreak)
        let dailiesCompleted = todayLogs.filter { $0.completed }.count
        let topTwo = getTopTwoHabitIds()
        let hour = Calendar.current.component(.hour, from: Date())
        let isEarlyBird = hour < 10
        let isNightOwl = hour >= 20
        let isPerfect = checkIfPerfectDay()
        let activeSkillsList = skills.filter { $0.isActive }
        
        let expGain = ScoringEngine.calculateExpGain(
            habit: habit,
            actualValue: value,
            streak: streak,
            totalDailiesCompleted: dailiesCompleted,
            activeSkills: activeSkillsList,
            permMultiplier: profile?.permExpMultiplier ?? 0,
            completedBeforeTenAm: isEarlyBird,
            completedAfterEightPm: isNightOwl,
            isPerfectDay: isPerfect,
            topTwoHabits: topTwo
        )
        
        log.expGained = Int32(expGain)
        
        if let lastDate = habit.lastCompletedDate {
            let calendar = Calendar.current
            if calendar.isDate(lastDate, inSameDayAs: Date()) {
                // Already completed today
            } else if calendar.isDateInYesterday(lastDate) {
                habit.currentStreak += 1
                habit.bestStreak = max(habit.bestStreak, habit.currentStreak)
            } else {
                habit.currentStreak = 1
            }
        } else {
            habit.currentStreak = 1
            habit.bestStreak = 1
        }
        habit.lastCompletedDate = Date()
        
        addExp(expGain)
        
        if habit.habitType == HabitType.weekly.rawValue, let quest = weeklyQuest {
            quest.progressCount += 1
            if quest.progressCount >= quest.targetCount && !quest.completed {
                quest.completed = true
                showChestModal = true
                grantChestReward()
            }
        }
        
        saveContext()
        loadData()
        checkAchievements()
        triggerHaptic(.success)
        
        setupUndo {
            self.context.delete(log)
            habit.currentStreak = max(0, habit.currentStreak - 1)
            self.profile?.expCurrent -= Int32(expGain)
            self.saveContext()
            self.loadData()
        }
    }
    
    func logBadHabit(habit: Habit) {
        let log = HabitLog(context: context)
        log.id = UUID()
        log.date = Date()
        log.penaltyTriggered = true
        log.habit = habit
        
        let hasIronWill = skills.contains { $0.key == SkillKey.ironWill.rawValue && $0.isActive }
        let penalty = ScoringEngine.calculatePenalty(
            baseExp: Int(habit.baseExp),
            hasIronWillActive: hasIronWill,
            ironWillUsesLeft: 2 - ironWillUsesThisWeek
        )
        
        if hasIronWill && ironWillUsesThisWeek < 2 {
            ironWillUsesThisWeek += 1
        }
        
        log.expGained = -Int32(penalty)
        
        let debuff = Debuff(context: context)
        debuff.id = UUID()
        debuff.key = habit.name ?? "penalty"
        debuff.appliedAt = Date()
        debuff.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
        debuff.expReduction = 0.05
        
        if let profile = profile {
            profile.expCurrent -= Int32(penalty)
            if profile.expCurrent < 0 { profile.expCurrent = 0 }
        }
        
        saveContext()
        loadData()
        triggerHaptic(.error)
    }
    
    func unlockSkill(_ skillKey: SkillKey) {
        guard skillPoints > 0 else { return }
        
        let skill = Skill(context: context)
        skill.id = UUID()
        skill.key = skillKey.rawValue
        skill.tier = Int16(skillKey.tier)
        skill.level = 1
        skill.isActive = true
        
        skillPoints -= 1
        
        saveContext()
        loadData()
        triggerHaptic(.success)
    }
    
    private func addExp(_ amount: Int) {
        guard let profile = profile else { return }
        
        profile.expCurrent += Int32(amount)
        
        while profile.expCurrent >= profile.expToNext {
            profile.expCurrent -= profile.expToNext
            profile.level += 1
            profile.expToNext = Int32(ScoringEngine.expForLevel(Int(profile.level)))
            
            skillPoints += 1
            showLevelUpModal = true
            triggerHaptic(.success)
            
            checkAchievements()
        }
    }
    
    private func grantChestReward() {
        guard let profile = profile else { return }
        
        if profile.permExpMultiplier < 0.10 {
            profile.permExpMultiplier += 0.01
        }
        
        let badge = Badge(context: context)
        badge.id = UUID()
        badge.key = "chest_\(UUID().uuidString.prefix(8))"
        badge.earnedAt = Date()
        
        saveContext()
    }
    
    private func checkIfPerfectDay() -> Bool {
        let goodHabits = habits.filter { $0.mode == HabitMode.good.rawValue && $0.habitType == HabitType.daily.rawValue }
        let completedToday = todayLogs.filter { $0.completed }.count
        return completedToday >= goodHabits.count && goodHabits.count > 0
    }
    
    private func checkAchievements() {
        let newAchievements = AchievementManager.shared.checkAchievements(gameManager: self)
        
        if let latest = newAchievements.first {
            lastAchievement = latest
            showAchievementModal = true
        }
    }
    
    private func getTopTwoHabitIds() -> [UUID] {
        let sorted = habits.sorted { $0.currentStreak > $1.currentStreak }
        return Array(sorted.prefix(2).compactMap { $0.id })
    }
    
    private func setupUndo(action: @escaping () -> Void) {
        lastAction = action
        showUndoSnackbar = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.showUndoSnackbar = false
            self.lastAction = nil
        }
    }
    
    func undo() {
        lastAction?()
        showUndoSnackbar = false
        lastAction = nil
    }
    
    // MARK: - Fetch Helpers
    
    private func fetchUserProfile() -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        return try? context.fetch(request).first
    }
    
    private func fetchActiveHabits() -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchTodayLogs() -> [HabitLog] {
        let request: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchActiveDebuffs() -> [Debuff] {
        let request: NSFetchRequest<Debuff> = Debuff.fetchRequest()
        request.predicate = NSPredicate(format: "expiresAt > %@", Date() as NSDate)
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchCurrentWeeklyQuest() -> WeeklyQuest? {
        let request: NSFetchRequest<WeeklyQuest> = WeeklyQuest.fetchRequest()
        let weekStart = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let start = Calendar.current.date(from: weekStart)!
        request.predicate = NSPredicate(format: "weekStartDate == %@", start as NSDate)
        return try? context.fetch(request).first
    }
    
    private func fetchSkills() -> [Skill] {
        let request: NSFetchRequest<Skill> = Skill.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    private func triggerHaptic(_ event: HapticEvent) {
#if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        let feedbackType: UINotificationFeedbackGenerator.FeedbackType

        switch event {
        case .success:
            feedbackType = .success
        case .warning:
            feedbackType = .warning
        case .error:
            feedbackType = .error
        }

        generator.notificationOccurred(feedbackType)
#else
        _ = event
#endif
    }
}
