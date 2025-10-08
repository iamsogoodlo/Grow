import SwiftUI

struct WorkoutView: View {
    @ObservedObject var workoutManager: GymManager
    @ObservedObject var gameManager: GameManager
    let profile: UserProfile?

    @State private var showLogWorkout = false
    @State private var selectedWorkout: Workout?

    private var headerSubtitle: String {
        if let profile = profile {
            return "Level \(profile.level) • \(Int(profile.expCurrent))/\(profile.expToNext) XP"
        }
        return "Track your workouts and gain XP"
    }

    private var recentWorkouts: [Workout] {
        Array(workoutManager.workouts.prefix(10))
    }

    private var thisWeekWorkouts: [Workout] {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return [] }
        return workoutManager.workouts.filter { workout in
            guard let date = workout.date else { return false }
            return date >= weekAgo
        }
    }

    private var totalMinutesThisWeek: Int {
        thisWeekWorkouts.reduce(0) { total, workout in
            total + Int(workout.duration)
        }
    }

    private var totalExperienceThisWeek: Int {
        gameManager.experienceTimeline
            .filter { event in
                event.source == .workout && Calendar.current.isDate(event.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
            }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    WorkoutSummaryCard(
                        subtitle: headerSubtitle,
                        workoutsThisWeek: thisWeekWorkouts.count,
                        minutesThisWeek: totalMinutesThisWeek,
                        experienceThisWeek: totalExperienceThisWeek
                    )

                    WorkoutQuickActionsCard(
                        onLogWorkout: { showLogWorkout = true }
                    )

                    if !recentWorkouts.isEmpty {
                        RecentWorkoutsSection(
                            workouts: recentWorkouts,
                            onSelectWorkout: { workout in
                                selectedWorkout = workout
                            }
                        )
                    } else {
                        WorkoutEmptyStateCard()
                    }
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 24)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogWorkout = true
                    } label: {
                        Label("Log Workout", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showLogWorkout) {
                WorkoutDetailSheet(
                    workoutManager: workoutManager,
                    gameManager: gameManager
                )
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailsView(workout: workout)
            }
        }
    }
}

// MARK: - Summary Card

struct WorkoutSummaryCard: View {
    let subtitle: String
    let workoutsThisWeek: Int
    let minutesThisWeek: Int
    let experienceThisWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This Week")
                        .font(.title2.weight(.bold))
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 20) {
                WorkoutStatPill(
                    title: "Workouts",
                    value: "\(workoutsThisWeek)",
                    icon: "dumbbell.fill",
                    color: .orange
                )

                WorkoutStatPill(
                    title: "Minutes",
                    value: "\(minutesThisWeek)",
                    icon: "clock.fill",
                    color: .blue
                )

                WorkoutStatPill(
                    title: "XP Earned",
                    value: "+\(experienceThisWeek)",
                    icon: "sparkles",
                    color: .purple
                )
            }
        }
        .cardStyle()
    }
}

struct WorkoutStatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Quick Actions

struct WorkoutQuickActionsCard: View {
    let onLogWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)

            Button(action: onLogWorkout) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.orange)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log Workout")
                            .font(.headline)
                        Text("Track your training session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }
}

// MARK: - Recent Workouts

struct RecentWorkoutsSection: View {
    let workouts: [Workout]
    let onSelectWorkout: (Workout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Workouts")
                    .font(.title3.weight(.bold))
                Spacer()
            }

            ForEach(workouts) { workout in
                WorkoutCardView(
                    workout: workout,
                    onTap: { onSelectWorkout(workout) }
                )
            }
        }
        .cardStyle()
    }
}

struct WorkoutCardView: View {
    let workout: Workout
    let onTap: () -> Void

    private var exerciseCount: Int {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return 0 }
        let names = sets.compactMap { $0.exercise?.lowercased() }
        return Set(names).count
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "dumbbell.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.title ?? "Workout")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Label("\(Int(workout.duration)) min", systemImage: "clock")
                        if exerciseCount > 0 {
                            Label("\(exerciseCount) exercises", systemImage: "list.bullet")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let date = workout.date {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.05))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct WorkoutEmptyStateCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No workouts yet")
                .font(.headline)

            Text("Log your first workout to start tracking your fitness journey and earning XP!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

// MARK: - Log Workout Sheet

struct WorkoutDetailSheet: View {
    @ObservedObject var workoutManager: GymManager
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    @State private var workoutName = ""
    @State private var duration = 30
    @State private var exercises: [WorkoutExerciseData] = []
    @State private var showAddExercise = false

    private var isValid: Bool {
        !workoutName.isEmpty && duration > 0
    }

    private var estimatedXP: Int {
        let baseXP = duration * 2
        let exerciseBonus = exercises.count * 5
        return baseXP + exerciseBonus
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
#if os(iOS)
                    TextField("Workout name", text: $workoutName)
                        .textInputAutocapitalization(.words)
#else
                    TextField("Workout name", text: $workoutName)
#endif

                    Stepper("Duration: \(duration) min", value: $duration, in: 5...300, step: 5)
                }

                Section {
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                if let sets = exercise.sets, let reps = exercise.reps {
                                    Text("\(sets) sets × \(reps) reps")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let weight = exercise.weight {
                                    Text("\(String(format: "%.1f", weight)) kg")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button(role: .destructive) {
                                exercises.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Button {
                        showAddExercise = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises (\(exercises.count))")
                }

                Section("Reward") {
                    Label("Estimated +\(estimatedXP) XP", systemImage: "sparkles")
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Log Workout")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        workoutManager.logWorkout(
                            name: workoutName,
                            duration: duration,
                            exercises: exercises,
                            gameManager: gameManager
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                    .bold()
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseSheet { exercise in
                    exercises.append(exercise)
                }
            }
        }
    }
}

// MARK: - Add Exercise Sheet

struct AddExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    let onAdd: (WorkoutExerciseData) -> Void

    @State private var exerciseName = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = ""
    @State private var notes = ""

    private var isValid: Bool {
        !exerciseName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
#if os(iOS)
                    TextField("Exercise name", text: $exerciseName)
                        .textInputAutocapitalization(.words)
#else
                    TextField("Exercise name", text: $exerciseName)
#endif
                }

                Section("Details") {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)

#if os(iOS)
                    TextField("Weight (kg, optional)", text: $weight)
                        .keyboardType(.decimalPad)
#else
                    TextField("Weight (kg, optional)", text: $weight)
#endif
                }

                Section("Notes (Optional)") {
                    TextField("Add notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Exercise")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let normalizedWeight = weight.replacingOccurrences(of: ",", with: ".")
                        let exercise = WorkoutExerciseData(
                            name: exerciseName,
                            sets: sets,
                            reps: reps,
                            weight: Double(normalizedWeight),
                            notes: notes.isEmpty ? nil : notes
                        )
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .bold()
                }
            }
        }
    }
}

// MARK: - Workout Details View

struct WorkoutDetailsView: View {
    let workout: Workout
    @Environment(\.dismiss) var dismiss

    private var exercises: [WorkoutExerciseData] {
        guard let rawSets = workout.sets as? Set<WorkoutSet> else { return [] }
        let orderedSets = rawSets.sorted { Int($0.orderIndex) < Int($1.orderIndex) }
        return orderedSets.map { set in
            WorkoutExerciseData(
                name: set.exercise ?? "Exercise",
                sets: Int(set.sets),
                reps: Int(set.reps),
                weight: set.weight == 0 ? nil : set.weight,
                notes: nil
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(workout.title ?? "Workout")
                            .font(.title.weight(.bold))

                        HStack(spacing: 16) {
                            Label("\(Int(workout.duration)) minutes", systemImage: "clock.fill")
                            if let date = workout.date {
                                Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.orange.opacity(0.1))
                    )

                    if !exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Exercises (\(exercises.count))")
                                .font(.headline)

                            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                                ExerciseDetailCard(exercise: exercise, index: index + 1)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Workout Details")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExerciseDetailCard: View {
    let exercise: WorkoutExerciseData
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(index).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                Text(exercise.name)
                    .font(.headline)

                Spacer()
            }

            if let sets = exercise.sets, let reps = exercise.reps {
                HStack(spacing: 16) {
                    Label("\(sets) sets", systemImage: "number")
                    Label("\(reps) reps", systemImage: "repeat")
                    if let weight = exercise.weight {
                        Label("\(String(format: "%.1f", weight)) kg", systemImage: "scalemass")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05))
                )
        )
    }
}
