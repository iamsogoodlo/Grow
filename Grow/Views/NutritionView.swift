import SwiftUI

struct NutritionView: View {
    @ObservedObject var nutritionManager: NutritionManager
    let profile: UserProfile?
    @ObservedObject var gameManager: GameManager

    @State private var showAddFood = false
    @State private var showAddWeight = false
    @State private var showScanner = false
    @State private var showSettings = false

    private var headerSubtitle: String {
        if let profile = profile {
            return "Level \(profile.level) • \(Int(profile.expCurrent))/\(profile.expToNext) XP"
        }
        return "Track meals, workouts, and XP"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    DailySummaryCard(
                        nutritionManager: nutritionManager,
                        profile: profile,
                        subtitle: headerSubtitle
                    )

                    QuickActionsGrid(
                        onAddFood: { showAddFood = true },
                        onAddWeight: { showAddWeight = true },
                        onScan: { showScanner = true },
                        onSettings: { showSettings = true }
                    )

                    ExperienceTicker(gameManager: gameManager)

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 24) {
                            TodayFoodsSection(
                                nutritionManager: nutritionManager,
                                showAddFood: $showAddFood
                            )

                            VStack(spacing: 24) {
                                WeightSection(
                                    nutritionManager: nutritionManager,
                                    showAddWeight: $showAddWeight,
                                    gameManager: gameManager
                                )

                                FavoritesSection(
                                    nutritionManager: nutritionManager,
                                    gameManager: gameManager
                                )
                            }
                            .frame(maxWidth: 340)
                        }

                        VStack(spacing: 24) {
                            TodayFoodsSection(
                                nutritionManager: nutritionManager,
                                showAddFood: $showAddFood
                            )

                            WeightSection(
                                nutritionManager: nutritionManager,
                                showAddWeight: $showAddWeight,
                                gameManager: gameManager
                            )

                            FavoritesSection(
                                nutritionManager: nutritionManager,
                                gameManager: gameManager
                            )
                        }
                    }
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 24)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }

                    Button {
                        showAddFood = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodSheet(
                    nutritionManager: nutritionManager,
                    gameManager: gameManager
                )
            }
            .sheet(isPresented: $showAddWeight) {
                AddWeightSheet(
                    nutritionManager: nutritionManager,
                    gameManager: gameManager
                )
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerSheet(
                    nutritionManager: nutritionManager,
                    gameManager: gameManager
                )
            }
            .sheet(isPresented: $showSettings) {
                NutritionSettingsSheet(
                    nutritionManager: nutritionManager,
                    profile: profile
                )
            }
        }
    }
}

// MARK: - Daily Summary

struct DailySummaryCard: View {
    @ObservedObject var nutritionManager: NutritionManager
    let profile: UserProfile?
    let subtitle: String

    private var totals: (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        nutritionManager.todayTotals
    }

    private var targets: (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        (
            Int(profile?.calorieTarget ?? 2000),
            Int(profile?.proteinTarget ?? 150),
            Int(profile?.carbsTarget ?? 200),
            Int(profile?.fatTarget ?? 60)
        )
    }

    private var remainingCalories: Int {
        max(targets.kcal - totals.kcal, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today")
                        .font(.title2.weight(.bold))
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(remainingCalories)")
                        .font(.title).bold()
                    Text("cal remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.accentColor.opacity(0.12))
                )
            }

            CalorieProgressView(
                consumed: totals.kcal,
                target: targets.kcal
            )

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(MacroType.allCases, id: \.self) { macro in
                        MacroSummaryPill(
                            type: macro,
                            value: value(for: macro),
                            target: target(for: macro)
                        )
                        .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(MacroType.allCases, id: \.self) { macro in
                        MacroSummaryPill(
                            type: macro,
                            value: value(for: macro),
                            target: target(for: macro)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func value(for macro: MacroType) -> Int {
        switch macro {
        case .protein: totals.protein
        case .carbs: totals.carbs
        case .fat: totals.fat
        }
    }

    private func target(for macro: MacroType) -> Int {
        switch macro {
        case .protein: targets.protein
        case .carbs: targets.carbs
        case .fat: targets.fat
        }
    }
}

enum MacroType: String, CaseIterable {
    case protein = "Protein"
    case carbs = "Carbs"
    case fat = "Fat"

    var accentColor: Color {
        switch self {
        case .protein: return .blue
        case .carbs: return .orange
        case .fat: return .purple
        }
    }
}

struct MacroSummaryPill: View {
    let type: MacroType
    let value: Int
    let target: Int

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(value) / Double(target), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(type.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(value)/\(target) g")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(type.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(type.accentColor.opacity(0.1))
        )
    }
}

struct CalorieProgressView: View {
    let consumed: Int
    let target: Int

    private var remaining: Int {
        max(target - consumed, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calories")
                    .font(.headline)
                Spacer()
                Text("\(consumed)/\(target)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(consumed), total: Double(max(target, 1)))
                .tint(.accentColor)

            HStack {
                Label("Consumed", systemImage: "flame.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(remaining) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsGrid: View {
    let onAddFood: () -> Void
    let onAddWeight: () -> Void
    let onScan: () -> Void
    let onSettings: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            QuickActionButton(
                title: "Log Food",
                systemImage: "plus.circle.fill",
                tint: .accentColor,
                action: onAddFood
            )

            QuickActionButton(
                title: "Scan",
                systemImage: "barcode.viewfinder",
                tint: .blue,
                action: onScan
            )

            QuickActionButton(
                title: "Log Weight",
                systemImage: "scalemass",
                tint: .purple,
                action: onAddWeight
            )

            QuickActionButton(
                title: "Settings",
                systemImage: "gearshape.fill",
                tint: .gray,
                action: onSettings
            )
        }
        .cardStyle()
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint)
                    )

                Text(title)
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Experience

struct ExperienceTicker: View {
    @ObservedObject var gameManager: GameManager

    private var recentEvents: [ExperienceEvent] {
        Array(gameManager.experienceTimeline.prefix(12))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent XP")
                    .font(.headline)
                Spacer()
                if let latest = recentEvents.first {
                    Text(latest.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if recentEvents.isEmpty {
                Text("Log meals or workouts to earn experience.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentEvents) { event in
                            ExperienceEventChip(event: event)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct ExperienceEventChip: View {
    let event: ExperienceEvent

    private var badgeColor: Color {
        switch event.source {
        case .habit: return .green
        case .habitPenalty: return .red
        case .workout: return .orange
        case .personalRecord: return .purple
        case .nutrition, .barcode: return .blue
        case .weight: return .mint
        case .manual: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("+\(event.amount) XP")
                    .font(.headline)
                Spacer()
            }

            Text(event.reason)
                .font(.caption)
                .lineLimit(2)

            Text(event.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(badgeColor.opacity(0.12))
        )
    }
}

// MARK: - Meals

struct TodayFoodsSection: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Binding var showAddFood: Bool

    private let meals = ["Breakfast", "Lunch", "Dinner", "Snack"]

    private func foods(for meal: String) -> [FoodLog] {
        nutritionManager.todayFoodLogs.filter { ($0.meal ?? meal) == meal }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Meals")
                    .font(.title3.weight(.bold))
                Spacer()
                Button(action: { showAddFood = true }) {
                    Label("Add Food", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            ForEach(meals, id: \.self) { meal in
                MealCard(
                    title: meal,
                    foods: foods(for: meal),
                    nutritionManager: nutritionManager,
                    onAdd: {
                        showAddFood = true
                    }
                )
            }
        }
        .cardStyle()
    }
}

struct MealCard: View {
    let title: String
    let foods: [FoodLog]
    @ObservedObject var nutritionManager: NutritionManager
    let onAdd: () -> Void

    private var totals: (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        let kcal = foods.reduce(0) { $0 + Int($1.kcal) }
        let protein = foods.reduce(0) { $0 + Int($1.protein) }
        let carbs = foods.reduce(0) { $0 + Int($1.carbs) }
        let fat = foods.reduce(0) { $0 + Int($1.fat) }
        return (kcal, protein, carbs, fat)
    }

    private var estimatedExp: Int {
        nutritionManager.calculateExpForFood(
            kcal: totals.kcal,
            protein: totals.protein,
            carbs: totals.carbs,
            fat: totals.fat
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text("\(totals.kcal) cal • est. +\(estimatedExp) XP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }

            if foods.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.secondary)
                    Text("Nothing logged yet. Scan or add a meal.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2))
                )
            } else {
                ForEach(Array(foods.enumerated()), id: \.element.objectID) { index, food in
                    FoodLogRow(
                        food: food,
                        nutritionManager: nutritionManager
                    )
                    .padding(.vertical, 4)

                    if index < foods.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05))
                )
        )
    }
}

struct FoodLogRow: View {
    let food: FoodLog
    @ObservedObject var nutritionManager: NutritionManager

    private var xpEstimate: Int {
        nutritionManager.calculateExpForFood(
            kcal: Int(food.kcal),
            protein: Int(food.protein),
            carbs: Int(food.carbs),
            fat: Int(food.fat)
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(food.label?.prefix(1).uppercased() ?? "?" )
                        .font(.headline)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(food.label ?? "Food")
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(food.kcal) cal", systemImage: "flame")
                    Label("P \(food.protein)g", systemImage: "bolt")
                    Label("C \(food.carbs)g", systemImage: "leaf")
                    Label("F \(food.fat)g", systemImage: "drop")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("+\(xpEstimate) XP")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }

            Spacer()

            if let meal = food.meal {
                Text(meal)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Weight

struct WeightSection: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Binding var showAddWeight: Bool
    @ObservedObject var gameManager: GameManager

    private var latest: WeightEntry? {
        nutritionManager.weightEntries.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }.first
    }

    private var previous: WeightEntry? {
        let sorted = nutritionManager.weightEntries.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        return sorted.dropFirst().first
    }

    private var weightExperience: ExperienceEvent? {
        gameManager.experienceTimeline.first { $0.source == .weight }
    }

    private var deltaText: String {
        guard let latest = latest, let prev = previous,
              let latestDate = latest.date, let prevDate = prev.date else {
            return "Log consistently to see trends"
        }

        let diff = latest.kg - prev.kg
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        let change = formatter.string(from: NSNumber(value: diff)) ?? String(format: "%.1f", diff)

        return "\(change) kg since \(prevDate.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight & Trend")
                    .font(.headline)
                Spacer()
                Button(action: { showAddWeight = true }) {
                    Label("Log Weight", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if let latest = latest, let date = latest.date {
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    Text(String(format: "%.1f", latest.kg))
                        .font(.system(size: 48, weight: .bold))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("kg")
                            .font(.headline)
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(deltaText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let weightExperience {
                            Text("Last weigh-in +\(weightExperience.amount) XP")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
            } else {
                Text("No weight entries yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

// MARK: - Favorites

struct FavoritesSection: View {
    @ObservedObject var nutritionManager: NutritionManager
    @ObservedObject var gameManager: GameManager

    var body: some View {
        Group {
            if nutritionManager.favoriteFoods.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Favorites")
                            .font(.headline)
                        Spacer()
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(nutritionManager.favoriteFoods.prefix(8)) { food in
                            FavoriteQuickAdd(
                                food: food,
                                nutritionManager: nutritionManager,
                                gameManager: gameManager
                            )
                        }
                    }
                }
                .cardStyle()
            }
        }
    }
}

struct FavoriteQuickAdd: View {
    let food: FoodLog
    @ObservedObject var nutritionManager: NutritionManager
    @ObservedObject var gameManager: GameManager

    private var xpEstimate: Int {
        nutritionManager.calculateExpForFood(
            kcal: Int(food.kcal),
            protein: Int(food.protein),
            carbs: Int(food.carbs),
            fat: Int(food.fat)
        )
    }

    var body: some View {
        Button {
            nutritionManager.logFood(
                label: food.label ?? "",
                kcal: Int(food.kcal),
                protein: Int(food.protein),
                carbs: Int(food.carbs),
                fat: Int(food.fat),
                meal: food.meal,
                gameManager: gameManager
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(food.label ?? "")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("\(food.kcal) cal • +\(xpEstimate) XP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.yellow.opacity(0.16))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Food & Weight

struct AddFoodSheet: View {
    @ObservedObject var nutritionManager: NutritionManager
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    @State private var label = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedMeal = "Breakfast"

    private let meals = ["Breakfast", "Lunch", "Dinner", "Snack"]

    private var previewXP: Int {
        nutritionManager.calculateExpForFood(
            kcal: Int(kcal) ?? 0,
            protein: Int(protein) ?? 0,
            carbs: Int(carbs) ?? 0,
            fat: Int(fat) ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food name", text: $label)
                    Picker("Meal", selection: $selectedMeal) {
                        ForEach(meals, id: \.self) { meal in
                            Text(meal).tag(meal)
                        }
                    }
                }

                Section("Calories") {
                    TextField("Calories", text: $kcal)
                        .keyboardType(.numberPad)
                }

                Section("Macros (Optional)") {
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.numberPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.numberPad)
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.numberPad)
                }

                Section("Reward") {
                    Label("Estimated +\(previewXP) XP", systemImage: "sparkles")
                        .foregroundStyle(.green)
                }
            }
            .navigationTitle("Log Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        nutritionManager.logFood(
                            label: label,
                            kcal: Int(kcal) ?? 0,
                            protein: Int(protein) ?? 0,
                            carbs: Int(carbs) ?? 0,
                            fat: Int(fat) ?? 0,
                            meal: selectedMeal,
                            gameManager: gameManager
                        )
                        dismiss()
                    }
                    .disabled(label.isEmpty || kcal.isEmpty)
                }
            }
        }
    }
}

struct AddWeightSheet: View {
    @ObservedObject var nutritionManager: NutritionManager
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    @State private var weight = ""
    @State private var date = Date()

    private var previewXP: Int {
        guard let kg = Double(weight) else { return 0 }
        return max(10, Int(kg.rounded()) / 10)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Reward") {
                    Label("Logging grants +\(previewXP) XP", systemImage: "sparkles")
                        .foregroundStyle(.green)
                }
            }
            .navigationTitle("Log Weight")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let kg = Double(weight) {
                            nutritionManager.logWeight(kg, date: date, gameManager: gameManager)
                            dismiss()
                        }
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
}

// MARK: - Settings

struct NutritionSettingsSheet: View {
    @ObservedObject var nutritionManager: NutritionManager
    let profile: UserProfile?
    @Environment(\.dismiss) var dismiss

    @State private var calorieTarget: Double = 2000
    @State private var proteinTarget: Double = 150
    @State private var carbTarget: Double = 200
    @State private var fatTarget: Double = 60

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Targets") {
                    Stepper(value: $calorieTarget, in: 1200...4500, step: 50) {
                        HStack {
                            Text("Calories")
                            Spacer()
                            Text("\(Int(calorieTarget))")
                        }
                    }

                    Stepper(value: $proteinTarget, in: 40...300, step: 5) {
                        HStack {
                            Text("Protein (g)")
                            Spacer()
                            Text("\(Int(proteinTarget))")
                        }
                    }

                    Stepper(value: $carbTarget, in: 40...450, step: 5) {
                        HStack {
                            Text("Carbs (g)")
                            Spacer()
                            Text("\(Int(carbTarget))")
                        }
                    }

                    Stepper(value: $fatTarget, in: 20...180, step: 5) {
                        HStack {
                            Text("Fat (g)")
                            Spacer()
                            Text("\(Int(fatTarget))")
                        }
                    }
                }

                Section("Sync") {
                    Button("Recalculate from Profile") {
                        nutritionManager.loadData()
                    }
                }
            }
            .navigationTitle("Nutrition Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                calorieTarget = Double(profile?.calorieTarget ?? 2000)
                proteinTarget = Double(profile?.proteinTarget ?? 150)
                carbTarget = Double(profile?.carbsTarget ?? 200)
                fatTarget = Double(profile?.fatTarget ?? 60)
            }
        }
    }
}

// MARK: - Barcode Scanner

struct BarcodeScannerSheet: View {
    @ObservedObject var nutritionManager: NutritionManager
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    @State private var scannedCode: String?
    @State private var label = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var meal = "Lunch"

    private var previewXP: Int {
        nutritionManager.calculateExpForFood(
            kcal: Int(kcal) ?? 0,
            protein: Int(protein) ?? 0,
            carbs: Int(carbs) ?? 0,
            fat: Int(fat) ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                BarcodeScannerView { code in
                    scannedCode = code
                    label = "Item \(code.suffix(4))"
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.top)

                if let scannedCode {
                    Form {
                        Section("Product") {
                            Text("Barcode: \(scannedCode)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Label", text: $label)
                            Picker("Meal", selection: $meal) {
                                ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { value in
                                    Text(value).tag(value)
                                }
                            }
                        }

                        Section("Nutrition") {
                            TextField("Calories", text: $kcal).keyboardType(.numberPad)
                            TextField("Protein", text: $protein).keyboardType(.numberPad)
                            TextField("Carbs", text: $carbs).keyboardType(.numberPad)
                            TextField("Fat", text: $fat).keyboardType(.numberPad)
                        }

                        Section("Reward") {
                            Label("Estimated +\(previewXP) XP", systemImage: "sparkles")
                                .foregroundStyle(.green)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "barcode")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Align the barcode within the frame to auto-fill the entry.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
            .navigationTitle("Scan Barcode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        nutritionManager.logFood(
                            label: label,
                            kcal: Int(kcal) ?? 0,
                            protein: Int(protein) ?? 0,
                            carbs: Int(carbs) ?? 0,
                            fat: Int(fat) ?? 0,
                            meal: meal,
                            gameManager: gameManager,
                            source: .barcode
                        )
                        dismiss()
                    }
                    .disabled(scannedCode == nil || label.isEmpty || kcal.isEmpty)
                }
            }
        }
    }
}

// MARK: - Styling Helpers

extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}

private struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
            )
    }
}

extension Color {
    static var cardBackground: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }

    static var screenBackground: Color {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
}
