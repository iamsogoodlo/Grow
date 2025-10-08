import SwiftUI

struct StravaHubView: View {
    @ObservedObject var gymManager: GymManager
    @ObservedObject var gameManager: GameManager
    let profile: UserProfile?
    let onMenuToggle: () -> Void

    @State private var showLogWorkout = false
    @State private var showLiftsDashboard = false
    @State private var selectedWorkout: Workout?

    private var workouts: [Workout] { gymManager.workouts }
    private var recentWorkouts: [Workout] { Array(workouts.prefix(10)) }

    private var thisWeekWorkouts: [Workout] {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return [] }
        return workouts.filter { workout in
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

    private var streakCount: Int {
        let calendar = Calendar.current
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        while workouts.contains(where: { workout in
            guard let workoutDate = workout.date else { return false }
            return calendar.isDate(workoutDate, inSameDayAs: date)
        }) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDay
        }

        return streak
    }

    private var topPersonalRecords: [(exercise: String, value: Double)] {
        gymManager.personalRecords
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    summaryCard
                    quickActionsCard
                    activityFeed
                    liftsPreview
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Strava")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MenuButton(action: onMenuToggle)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLogWorkout = true
                    } label: {
                        Label("Log workout", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showLogWorkout) {
                WorkoutDetailSheet(
                    workoutManager: gymManager,
                    gameManager: gameManager
                )
            }
            .sheet(isPresented: $showLiftsDashboard) {
                NavigationStack {
                    LiftsView(gymManager: gymManager, gameManager: gameManager)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showLiftsDashboard = false }
                            }
                        }
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailsView(workout: workout)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This Week")
                        .font(.title3.weight(.bold))
                    if let profile {
                        Text("Level \(profile.level) • \(Int(profile.expCurrent))/\(profile.expToNext) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(streakCount) day streak")
                        .font(.headline)
                    Text("Keep it going!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 16) {
                statPill(title: "Workouts", value: "\(thisWeekWorkouts.count)", icon: "figure.run", tint: .orange)
                statPill(title: "Minutes", value: "\(totalMinutesThisWeek)", icon: "clock.fill", tint: .blue)
                statPill(title: "XP Earned", value: "+\(totalExperienceThisWeek)", icon: "sparkles", tint: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 16) {
                Button {
                    showLogWorkout = true
                } label: {
                    actionTile(
                        icon: "figure.strengthtraining.traditional",
                        title: "Log Activity",
                        subtitle: "Record cardio or lifts",
                        tint: .orange
                    )
                }

                Button {
                    showLiftsDashboard = true
                } label: {
                    actionTile(
                        icon: "dumbbell.fill",
                        title: "Lifts Dashboard",
                        subtitle: "Review PRs & volume",
                        tint: .purple
                    )
                }
            }

            if let latest = workouts.first, let date = latest.date {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Last workout")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(latest.title ?? "Workout")
                        .font(.headline)
                    Text("\(formattedDate(date)) • \(Int(latest.duration)) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Feed")
                    .font(.headline)
                Spacer()
                if !recentWorkouts.isEmpty {
                    Text("Latest \(recentWorkouts.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if recentWorkouts.isEmpty {
                Text("Log your first workout to see it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(recentWorkouts, id: \.objectID) { workout in
                        Button {
                            selectedWorkout = workout
                        } label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.title ?? "Workout")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(formattedDate(workout.date ?? Date())) • \(Int(workout.duration)) min")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.cardBackground)
                            )
                        }
                        .buttonStyle(.plain)
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

    private var liftsPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Lifts")
                    .font(.headline)
                Spacer()
                Button("Open Lifts") { showLiftsDashboard = true }
                    .font(.footnote.weight(.semibold))
            }

            if topPersonalRecords.isEmpty {
                Text("Log strength workouts to build your PR library.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(topPersonalRecords, id: \.exercise) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.exercise)
                                    .font(.headline)
                                Text("Best est. 1RM: \(String(format: "%.1f", record.value)) kg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.cardBackground)
                        )
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

    private func statPill(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
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
                .fill(tint.opacity(0.12))
        )
    }

    private func actionTile(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.85), tint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
