import Foundation
import CoreData

@objc(Badge)
public class Badge: NSManagedObject {}

extension Badge {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Badge> {
        return NSFetchRequest<Badge>(entityName: "Badge")
    }

    @NSManaged public var earnedAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var key: String?
}

extension Badge: Identifiable {}

@objc(Debuff)
public class Debuff: NSManagedObject {}

extension Debuff {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Debuff> {
        return NSFetchRequest<Debuff>(entityName: "Debuff")
    }

    @NSManaged public var appliedAt: Date?
    @NSManaged public var expiresAt: Date?
    @NSManaged public var expReduction: Double
    @NSManaged public var id: UUID?
    @NSManaged public var key: String?
}

extension Debuff: Identifiable {}

@objc(Habit)
public class Habit: NSManagedObject {}

extension Habit {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }

    @NSManaged public var baseExp: Int32
    @NSManaged public var bestStreak: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var currentStreak: Int32
    @NSManaged public var habitType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var lastCompletedDate: Date?
    @NSManaged public var mode: String?
    @NSManaged public var name: String?
    @NSManaged public var scalar: String?
    @NSManaged public var targetNumber: Double
    @NSManaged public var logs: HabitLog?
}

extension Habit: Identifiable {}

@objc(HabitLog)
public class HabitLog: NSManagedObject {}

extension HabitLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitLog> {
        return NSFetchRequest<HabitLog>(entityName: "HabitLog")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var date: Date?
    @NSManaged public var expGained: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var penaltyTriggered: Bool
    @NSManaged public var valueNumber: Double
    @NSManaged public var habit: Habit?
}

extension HabitLog: Identifiable {}

@objc(Skill)
public class Skill: NSManagedObject {}

extension Skill {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Skill> {
        return NSFetchRequest<Skill>(entityName: "Skill")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var key: String?
    @NSManaged public var level: Int16
    @NSManaged public var tier: Int16
}

extension Skill: Identifiable {}

@objc(UserProfile)
public class UserProfile: NSManagedObject {}

extension UserProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var cleansesAvailable: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var displayName: String?
    @NSManaged public var expCurrent: Int32
    @NSManaged public var expToNext: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var level: Int32
    @NSManaged public var permExpMultiplier: Double
    @NSManaged public var playerClass: String?
    @NSManaged public var streakShieldAvailable: Bool
}

extension UserProfile: Identifiable {}

@objc(WeeklyQuest)
public class WeeklyQuest: NSManagedObject {}

extension WeeklyQuest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeeklyQuest> {
        return NSFetchRequest<WeeklyQuest>(entityName: "WeeklyQuest")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var progressCount: Int32
    @NSManaged public var targetCount: Int32
    @NSManaged public var weekStartDate: Date?
}

extension WeeklyQuest: Identifiable {}
