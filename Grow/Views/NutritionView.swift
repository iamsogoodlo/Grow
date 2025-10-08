//
//  NutritionView.swift
//  Grow
//
//  Created by Bryan Liu on 2025-10-07.
//


import SwiftUI

struct NutritionView: View {
    @ObservedObject var nutritionManager: NutritionManager
    let profile: UserProfile?
    @State private var showAddFood = false
    @State private var showAddWeight = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Macro Rings
                    MacroRingsCard(
                        nutritionManager: nutritionManager,
                        profile: profile
                    )
                    
                    // Today's Foods
                    TodayFoodsSection(
                        nutritionManager: nutritionManager,
                        showAddFood: $showAddFood
                    )
                    
                    // Weight Tracking
                    WeightSection(
                        nutritionManager: nutritionManager,
                        showAddWeight: $showAddWeight
                    )
                    
                    // Quick Add Favorites
                    FavoritesSection(nutritionManager: nutritionManager)
                }
                .padding(.vertical)
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodSheet(nutritionManager: nutritionManager)
            }
            .sheet(isPresented: $showAddWeight) {
                AddWeightSheet(nutritionManager: nutritionManager)
            }
        }
    }
}

// MARK: - Macro Rings Card

struct MacroRingsCard: View {
    @ObservedObject var nutritionManager: NutritionManager
    let profile: UserProfile?
    
    var totals: (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        nutritionManager.todayTotals
    }
    
    var targets: (kcal: Int, protein: Int, carbs: Int, fat: Int) {
        (
            Int(profile?.calorieTarget ?? 2000),
            Int(profile?.proteinTarget ?? 150),
            Int(profile?.carbsTarget ?? 200),
            Int(profile?.fatTarget ?? 60)
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Today's Macros")
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(totals.kcal)/\(targets.kcal) cal")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 30) {
                MacroRing(
                    value: totals.protein,
                    target: targets.protein,
                    label: "Protein",
                    color: .blue
                )
                
                MacroRing(
                    value: totals.carbs,
                    target: targets.carbs,
                    label: "Carbs",
                    color: .orange
                )
                
                MacroRing(
                    value: totals.fat,
                    target: targets.fat,
                    label: "Fat",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct MacroRing: View {
    let value: Int
    let target: Int
    let label: String
    let color: Color
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(value) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(value)")
                        .font(.title3)
                        .bold()
                    Text("g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Today's Foods Section

struct TodayFoodsSection: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Binding var showAddFood: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Today's Meals")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showAddFood = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if nutritionManager.todayFoodLogs.isEmpty {
                Text("No meals logged yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(nutritionManager.todayFoodLogs) { food in
                    FoodLogRow(food: food, nutritionManager: nutritionManager)
                }
            }
        }
    }
}

struct FoodLogRow: View {
    let food: FoodLog
    @ObservedObject var nutritionManager: NutritionManager
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(food.label ?? "Food")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    if food.meal != nil {
                        Text(food.meal!)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("\(food.kcal) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if food.protein > 0 {
                        Text("P:\(food.protein)g")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                nutritionManager.toggleFavorite(food)
            }) {
                Image(systemName: food.isFavorite ? "star.fill" : "star")
                    .foregroundColor(food.isFavorite ? .yellow : .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Weight Section

struct WeightSection: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Binding var showAddWeight: Bool
    
    var currentWeight: Double? {
        nutritionManager.weightEntries.first?.kg
    }
    
    var trend: Double? {
        nutritionManager.weightEMA()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Weight Tracking")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showAddWeight = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 30) {
                if let weight = currentWeight {
                    WeightStatBox(
                        value: String(format: "%.1f", weight),
                        label: "Current",
                        color: .blue
                    )
                }
                
                if let trendWeight = trend {
                    WeightStatBox(
                        value: String(format: "%.1f", trendWeight),
                        label: "Trend",
                        color: .green
                    )
                }
                
                if currentWeight == nil {
                    Text("No weight data yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct WeightStatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title)
                .bold()
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("kg")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Favorites Section

struct FavoritesSection: View {
    @ObservedObject var nutritionManager: NutritionManager
    
    var body: some View {
        if !nutritionManager.favoriteFoods.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
                Text("Favorites")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nutritionManager.favoriteFoods.prefix(5)) { food in
                            FavoriteQuickAdd(food: food, nutritionManager: nutritionManager)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct FavoriteQuickAdd: View {
    let food: FoodLog
    @ObservedObject var nutritionManager: NutritionManager
    
    var body: some View {
        Button(action: {
            nutritionManager.logFood(
                label: food.label ?? "",
                kcal: Int(food.kcal),
                protein: Int(food.protein),
                carbs: Int(food.carbs),
                fat: Int(food.fat)
            )
        }) {
            VStack(spacing: 8) {
                Text("⭐️")
                    .font(.title)
                
                Text(food.label ?? "")
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(food.kcal) cal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Food Sheet

struct AddFoodSheet: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var label = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedMeal = "Breakfast"
    
    let meals = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationView {
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
                }
                
                Section("Macros (Optional)") {
                    TextField("Protein (g)", text: $protein)
                    TextField("Carbs (g)", text: $carbs)
                    TextField("Fat (g)", text: $fat)
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
                            meal: selectedMeal
                        )
                        dismiss()
                    }
                    .disabled(label.isEmpty || kcal.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Weight Sheet

struct AddWeightSheet: View {
    @ObservedObject var nutritionManager: NutritionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var weight = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Weight") {
                    TextField("Weight (kg)", text: $weight)
                }
                
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
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
                            nutritionManager.logWeight(kg, date: date)
                            dismiss()
                        }
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
}
