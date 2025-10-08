import SwiftUI

struct HabitTrackerView: View {
    let onMenuToggle: () -> Void

    @State private var habits: [HabitTrackerItem] = [
        HabitTrackerItem(
            name: "Morning mobility",
            goal: "Stretch for 5 minutes",
            streak: 3,
            lastCompletion: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        ),
        HabitTrackerItem(name: "Hydration", goal: "Drink 8 glasses of water", streak: 0, lastCompletion: nil)
    ]
    @State private var showAddHabit = false

    private var calendar: Calendar { Calendar.current }

    private var completedToday: Int {
        habits.filter { $0.isCompleted(today: Date(), calendar: calendar) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    habitList
                    routinesTips
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Habit Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MenuButton(action: onMenuToggle)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHabit = true
                    } label: {
                        Label("New Habit", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitView { habit in
                    habits.append(habit)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily momentum")
                .font(.headline)
            Text("Check off small wins every day to build lasting routines and boost your Grow profile.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 16) {
                habitStat(title: "Habits", value: "\(habits.count)", icon: "list.bullet")
                habitStat(title: "Completed", value: "\(completedToday)", icon: "checkmark.circle.fill")
                habitStat(title: "Best streak", value: "\(habits.map(\.streak).max() ?? 0)", icon: "flame.fill")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var habitList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's habits")
                .font(.headline)

            if habits.isEmpty {
                Text("Add your first habit to start building your streaks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(habits.indices, id: \.self) { index in
                        HabitRow(habit: habits[index], calendar: calendar) { completed in
                            toggleHabitCompletion(at: index, completed: completed)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var routinesTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency ideas")
                .font(.headline)

            HabitTipRow(icon: "bell", title: "Stack habits", description: "Attach a new routine to one you already do, like stretching after brushing your teeth.")
            HabitTipRow(icon: "sparkles", title: "Celebrate streaks", description: "Give yourself a reward when you hit a seven-day streak.")
            HabitTipRow(icon: "person.2.fill", title: "Stay accountable", description: "Share progress with a friend or coach to stay motivated.")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func habitStat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.mint)
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.mint.opacity(0.12))
        )
    }

    private func toggleHabitCompletion(at index: Int, completed: Bool) {
        guard habits.indices.contains(index) else { return }

        if completed {
            habits[index].markCompleted(on: Date(), calendar: calendar)
        } else {
            habits[index].resetToday(calendar: calendar)
        }
    }
}

private struct HabitTipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.mint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HabitRow: View {
    @State private var isExpanded = false
    let habit: HabitTrackerItem
    let calendar: Calendar
    let onToggle: (Bool) -> Void

    private var completedToday: Bool {
        habit.isCompleted(today: Date(), calendar: calendar)
    }

    private var streakText: String {
        completedToday ? "Streak: \(habit.streak) days" : "Current streak: \(habit.streak)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.headline)
                    Text(habit.goal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: .init(
                    get: { completedToday },
                    set: { onToggle($0) }
                )) {
                    Text("")
                }
                .toggleStyle(SwitchToggleStyle(tint: .mint))
                .labelsHidden()
            }

            HStack {
                Label(streakText, systemImage: "flame")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    if let last = habit.lastCompletion {
                        Text("Last completed: \(formatted(last))")
                    }
                    Text("Tip: Block time for this habit in your calendar to make it non-negotiable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var goal: String = ""

    let onSave: (HabitTrackerItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name", text: $name)
                    TextField("Reminder", text: $goal)
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let habit = HabitTrackerItem(name: name.isEmpty ? "New Habit" : name, goal: goal.isEmpty ? "Stay consistent" : goal)
                        onSave(habit)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct HabitTrackerItem: Identifiable {
    let id = UUID()
    var name: String
    var goal: String
    var streak: Int
    var lastCompletion: Date?

    init(name: String, goal: String, streak: Int = 0, lastCompletion: Date? = nil) {
        self.name = name
        self.goal = goal
        self.streak = streak
        self.lastCompletion = lastCompletion
    }

    func isCompleted(today: Date, calendar: Calendar) -> Bool {
        guard let lastCompletion else { return false }
        return calendar.isDate(lastCompletion, inSameDayAs: today)
    }

    mutating func markCompleted(on date: Date, calendar: Calendar) {
        if let lastCompletion, calendar.isDate(lastCompletion, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: date) ?? date) {
            streak += 1
        } else if !isCompleted(today: date, calendar: calendar) {
            streak = max(streak, 0) + 1
        }

        lastCompletion = date
    }

    mutating func resetToday(calendar: Calendar) {
        guard let lastCompletion else { return }
        if calendar.isDateInToday(lastCompletion) {
            lastCompletion = nil
            streak = max(streak - 1, 0)
        }
    }
}
