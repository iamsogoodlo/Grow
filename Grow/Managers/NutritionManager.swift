import CoreData
import Foundation
import Combine

class NutritionManager: ObservableObject {
    let context: NSManagedObjectContext
    
    @Published var todayFoodLogs: [FoodLog] = []
    @Published var recentFoods: [FoodLog] = []
    @Published var favoriteFoods: [FoodLog] = []
    @Published var weightEntries: [WeightEntry] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    func loadData() {
        todayFoodLogs = fetchTodayFoodLogs()
        recentFoods = fetchRecentFoods()
        favoriteFoods = fetchFavoriteFoods()
        weightEntries = fetchWeightEntries()
    }
    
    // MARK: - Food Logging
    
    func logFood(label: String, kcal: Int, protein: Int = 0, carbs: Int = 0, fat: Int = 0, meal: String? = nil) {
        let log = FoodLog(context: context)
        log.id = UUID()
        log.date = Date()
        log.label = label
        log.kcal = Int32(kcal)
        log.protein = Int32(protein)
        log.carbs = Int32(carbs)
        log.fat = Int32(fat)
        log.meal = meal
        log.isFavorite = false
        
        saveContext()
        loadData()
    }
    
    func toggleFavorite(_ food: FoodLog) {
        food.isFavorite.toggle()
        saveContext()
        loadData()
    }
    
    func deleteFood(_ food: FoodLog) {
        context.delete(food)
        saveContext()
        loadData()
    }
    
    // MARK: - Weight Tracking
    
    func logWeight(_ kg: Double, date: Date = Date()) {
        let entry = WeightEntry(context: context)
        entry.id = UUID()
        entry.date = date
        entry.kg = kg
        
        saveContext()
        loadData()
    }
    
    func deleteWeightEntry(_ entry: WeightEntry) {
        context.delete(entry)
        saveContext()
        loadData()
    }
    
    // MARK: - Calculations
    
    var todayTotals: (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        let kcal = todayFoodLogs.reduce(0) { $0 + Int($1.kcal) }
        let protein = todayFoodLogs.reduce(0) { $0 + Int($1.protein) }
        let carbs = todayFoodLogs.reduce(0) { $0 + Int($1.carbs) }
        let fat = todayFoodLogs.reduce(0) { $0 + Int($1.fat) }
        return (kcal, protein, carbs, fat)
    }
    
    func weightTrend(days: Int = 7) -> [Double] {
        let sorted = weightEntries.sorted { $0.date ?? Date() > $1.date ?? Date() }
        return Array(sorted.prefix(days).map { $0.kg })
    }
    
    func weightEMA(alpha: Double = 0.3) -> Double? {
        guard !weightEntries.isEmpty else { return nil }
        let sorted = weightEntries.sorted { $0.date ?? Date() < $1.date ?? Date() }
        
        var ema = sorted.first?.kg ?? 0
        for entry in sorted.dropFirst() {
            ema = alpha * entry.kg + (1 - alpha) * ema
        }
        return ema
    }
    
    // MARK: - Fetch Helpers
    
    private func fetchTodayFoodLogs() -> [FoodLog] {
        let request: NSFetchRequest<FoodLog> = FoodLog.fetchRequest()
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchRecentFoods() -> [FoodLog] {
        let request: NSFetchRequest<FoodLog> = FoodLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 10
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchFavoriteFoods() -> [FoodLog] {
        let request: NSFetchRequest<FoodLog> = FoodLog.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        request.sortDescriptors = [NSSortDescriptor(key: "label", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchWeightEntries() -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 90
        return (try? context.fetch(request)) ?? []
    }
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
