import SwiftUI

struct YukaScannerView: View {
    @ObservedObject var nutritionManager: NutritionManager
    @ObservedObject var gameManager: GameManager
    let onMenuToggle: () -> Void

    @State private var scannedCode: String?
    @State private var label: String = ""
    @State private var kcal: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var meal: String = "Lunch"
    @State private var showingHistory = false
    @State private var showingConfirmation = false

    private var estimatedXP: Int {
        nutritionManager.calculateExpForFood(
            kcal: Int(kcal) ?? 0,
            protein: Int(protein) ?? 0,
            carbs: Int(carbs) ?? 0,
            fat: Int(fat) ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerCard

                    scannerCard

                    if let scannedCode {
                        entryForm(for: scannedCode)
                    } else {
                        placeholderCard
                    }

                    recentHistory
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Yuka")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MenuButton(action: onMenuToggle)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .disabled(nutritionManager.recentFoods.isEmpty)
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    List(nutritionManager.recentFoods, id: \.objectID) { food in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(food.label ?? "Unnamed Item")
                                .font(.headline)
                            Text("\(food.kcal) kcal • P: \(food.protein)g • C: \(food.carbs)g • F: \(food.fat)g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .navigationTitle("Recent Scans")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingHistory = false }
                        }
                    }
                }
            }
            .alert("Log item?", isPresented: $showingConfirmation) {
                Button("Log to diary", role: .none) {
                    logFoodEntry()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Add \(label.isEmpty ? "this item" : label) to your nutrition diary?")
            }
        }
    }

    private func logFoodEntry() {
        guard !label.isEmpty, let calories = Int(kcal) else { return }

        nutritionManager.logFood(
            label: label,
            kcal: calories,
            protein: Int(protein) ?? 0,
            carbs: Int(carbs) ?? 0,
            fat: Int(fat) ?? 0,
            meal: meal,
            gameManager: gameManager,
            source: .barcode
        )

        resetForm()
    }

    private func resetForm() {
        scannedCode = nil
        label = ""
        kcal = ""
        protein = ""
        carbs = ""
        fat = ""
        meal = "Lunch"
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Instant nutrition insights", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)

            Text("Scan a barcode to pre-fill nutrition details and award XP when you log meals.")
                .font(.body)

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Logged Meals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(nutritionManager.todayFoodLogs.count)")
                        .font(.title2.weight(.bold))
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("Calories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(nutritionManager.todayTotals.kcal)")
                        .font(.title2.weight(.bold))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var scannerCard: some View {
        VStack(spacing: 16) {
            BarcodeScannerView { code in
                scannedCode = code
                label = label.isEmpty ? "Item \(code.suffix(4))" : label
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 12) {
                Image(systemName: "barcode")
                Text("Align the barcode inside the frame. We'll auto-fill everything we can.")
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func entryForm(for code: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scan Result")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Text("Barcode: \(code)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Label", text: $label)
                    .textFieldStyle(.roundedBorder)

                Picker("Meal", selection: $meal) {
                    ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    nutrientField(title: "Calories", value: $kcal, suffix: "kcal")
                    nutrientField(title: "Protein", value: $protein, suffix: "g")
                }

                GridRow {
                    nutrientField(title: "Carbs", value: $carbs, suffix: "g")
                    nutrientField(title: "Fat", value: $fat, suffix: "g")
                }
            }

            Label("Estimated +\(estimatedXP) XP", systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)

            Button {
                showingConfirmation = true
            } label: {
                Text("Log to MyFitnessPal")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.85), .green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .disabled(label.isEmpty || kcal.isEmpty)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No scan yet")
                .font(.headline)
            Text("Point your camera at a barcode to start tracking. We'll remember your last scans for quick logging.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Logs")
                    .font(.headline)
                Spacer()
                Button("See all") { showingHistory = true }
                    .font(.footnote.weight(.semibold))
                    .disabled(nutritionManager.recentFoods.isEmpty)
            }

            if nutritionManager.recentFoods.isEmpty {
                Text("Your most recent scans will appear here for quick re-logging.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(nutritionManager.recentFoods.prefix(3), id: \.objectID) { food in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.label ?? "Unnamed Item")
                                .font(.headline)
                            Text("\(food.kcal) kcal • Protein \(food.protein)g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.screenBackground)
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func nutrientField(title: String, value: Binding<String>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("0", text: value)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                Text(suffix)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.screenBackground)
            )
        }
    }
}
