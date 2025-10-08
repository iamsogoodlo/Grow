import SwiftUI

struct LiftsView: View {
    @ObservedObject var gymManager: GymManager
    @ObservedObject var gameManager: GameManager

    @State private var showNewWorkout = false
    @State private var selectedRange: LiftHistoryRange = .ninetyDays

    private var workouts: [Workout] { gymManager.workouts }
    private var latestWorkout: Workout? { workouts.first }

    private var rangeFilteredWorkouts: [Workout] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -selectedRange.lengthInDays + 1, to: Date()) else {
            return workouts
        }
        let lowerBound = Calendar.current.startOfDay(for: startDate)
        return workouts.filter { workout in
            guard let date = workout.date else { return false }
            return date >= lowerBound
        }
    }

    private var previousRangeWorkouts: [Workout] {
        guard let previousEnd = Calendar.current.date(byAdding: .day, value: -selectedRange.lengthInDays, to: Date()),
              let previousStart = Calendar.current.date(byAdding: .day, value: -selectedRange.lengthInDays * 2 + 1, to: Date()) else {
            return []
        }

        let windowStart = Calendar.current.startOfDay(for: previousStart)
        let windowEnd = Calendar.current.endOfDay(for: previousEnd)

        return workouts.filter { workout in
            guard let date = workout.date else { return false }
            return date >= windowStart && date <= windowEnd
        }
    }

    private var overviewMetrics: LiftOverviewMetrics {
        let currentSnapshot = LiftOverviewMetricsSnapshot.capture(from: rangeFilteredWorkouts)
        let previousSnapshot = previousRangeWorkouts.isEmpty ? nil : LiftOverviewMetricsSnapshot.capture(from: previousRangeWorkouts)
        return LiftOverviewMetrics.make(current: currentSnapshot, previous: previousSnapshot)
    }

    private var trendPoints: [LiftTrendPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: rangeFilteredWorkouts) { workout -> Date in
            let date = workout.date ?? Date()
            return calendar.startOfDay(for: date)
        }

        let sortedDates = grouped.keys.sorted()
        return sortedDates.map { date in
            let volume = grouped[date]?.reduce(0.0) { $0 + workoutVolume($1) } ?? 0
            return LiftTrendPoint(date: date, totalVolume: volume)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    OverviewSection(
                        metrics: overviewMetrics,
                        selectedRange: $selectedRange,
                        trendPoints: trendPoints
                    )

                    GoalsSection(personalRecords: gymManager.personalRecords)

                    if let workout = latestWorkout {
                        SpotlightWorkoutCard(
                            workout: workout,
                            volume: workoutVolume(workout),
                            totalReps: totalReps(for: workout)
                        )
                    }

                    ProgramsYouFollowSection()

                    RecentSessionsSection(
                        workouts: workouts,
                        calculateVolume: workoutVolume,
                        calculateXP: estimatedXP
                    )
                }
                .padding(.vertical, 24)
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lifts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewWorkout = true }) {
                        Label("Log workout", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showNewWorkout) {
                NewWorkoutSheet(gymManager: gymManager, gameManager: gameManager)
            }
        }
    }

    private func workoutVolume(_ workout: Workout) -> Double {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return 0 }
        return sets.reduce(0.0) { partialResult, set in
            partialResult + (set.weight * Double(set.sets) * Double(set.reps))
        }
    }

    private func totalReps(for workout: Workout) -> Int {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return 0 }
        return sets.reduce(0) { $0 + Int($1.sets * $1.reps) }
    }

    private func estimatedXP(for workout: Workout) -> Int {
        let duration = Int(workout.duration)
        let baseExp = max(duration / 2, 10)
        let volumeBonus = min(Int(workoutVolume(workout) / 900), 60)
        let exp = baseExp + volumeBonus
        return exp
    }
}

// MARK: - Overview

private struct OverviewSection: View {
    let metrics: LiftOverviewMetrics
    @Binding var selectedRange: LiftHistoryRange
    let trendPoints: [LiftTrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overview")
                        .font(.title3.weight(.semibold))
                    Text(selectedRange.subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()

                RangePicker(selectedRange: $selectedRange)
            }

            SparklineCard(trendPoints: trendPoints, accent: .pink)
                .frame(height: 160)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(metrics.metrics) { metric in
                    OverviewMetricTile(metric: metric)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
    }
}

private struct RangePicker: View {
    @Binding var selectedRange: LiftHistoryRange

    var body: some View {
        HStack(spacing: 8) {
            ForEach(LiftHistoryRange.allCases) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.shortLabel)
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(range == selectedRange ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .foregroundColor(range == selectedRange ? .accentColor : .secondary)
            }
        }
    }
}

private struct SparklineCard: View {
    let trendPoints: [LiftTrendPoint]
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.18), accent.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))

            if trendPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(accent)
                    Text("Complete a workout to see trends")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Volume trend")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)

                    SparklineView(points: trendPoints, accent: accent)
                        .frame(height: 90)

                    HStack {
                        Text(metricsSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Label("Volume", systemImage: "dumbbell.fill")
                            .font(.caption.weight(.semibold))
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(accent)
                    }
                }
                .padding(16)
            }
        }
    }

    private var metricsSummary: String {
        guard let last = trendPoints.last?.totalVolume else { return "" }
        if let previous = trendPoints.dropLast().last?.totalVolume {
            let delta = last - previous
            if delta == 0 {
                return "No change vs last session"
            } else if delta > 0 {
                return String(format: "+%.0f kg volume vs last session", delta)
            } else {
                return String(format: "%.0f kg less volume than last session", delta)
            }
        }
        return String(format: "Last session volume %.0f kg", last)
    }
}

private struct OverviewMetricTile: View {
    let metric: LiftMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(metric.title, systemImage: metric.icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(metric.value)
                .font(.title3.weight(.semibold))
            if let delta = metric.deltaText {
                Text(delta)
                    .font(.caption)
                    .foregroundStyle(delta.contains("+") ? Color.green : Color.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Goals

private struct GoalsSection: View {
    let personalRecords: [String: Double]

    private var goals: [LiftGoal] {
        let defaults: [LiftGoal] = [
            LiftGoal(name: "Squat", goal: 240, unit: "kg", accent: .orange),
            LiftGoal(name: "Bench", goal: 180, unit: "kg", accent: .blue),
            LiftGoal(name: "Deadlift", goal: 300, unit: "kg", accent: .purple)
        ]

        return defaults.map { goal in
            let current = personalRecords[goal.name] ?? personalRecords[goal.name + " Press"] ?? 0
            return goal.with(current: current)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My goals")
                    .font(.headline)
                Spacer()
                Label("Update", systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(goals) { goal in
                        GoalProgressRing(goal: goal)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct GoalProgressRing: View {
    let goal: LiftGoal

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 10)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: min(goal.progress, 1))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [goal.accent, goal.accent.opacity(0.4), goal.accent]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 90, height: 90)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f", goal.current))
                        .font(.headline)
                    Text(goal.unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text(goal.name)
                    .font(.subheadline.weight(.semibold))
                Text(goal.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Spotlight workout

private struct SpotlightWorkoutCard: View {
    let workout: Workout
    let volume: Double
    let totalReps: Int

    private var sets: [WorkoutSet] {
        guard let rawSets = workout.sets as? Set<WorkoutSet> else { return [] }
        return rawSets.sorted { Int($0.orderIndex) < Int($1.orderIndex) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.title ?? "Latest session")
                        .font(.headline)
                    if let date = workout.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let imageName = sets.first?.exercise?.lowercased() {
                    Image(systemName: icon(for: imageName))
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }

            HStack(spacing: 12) {
                MetricChip(title: "Volume", value: String(format: "%.0f kg", volume))
                MetricChip(title: "Reps", value: "\(totalReps)")
                MetricChip(title: "XP", value: "+\(max(Int(workout.expGranted), estimatedXP()))")
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                    WorkoutSetRow(set: set, index: index + 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    private func estimatedXP() -> Int {
        let duration = Int(workout.duration)
        let baseExp = max(duration / 2, 10)
        let volumeBonus = min(Int(volume / 900), 60)
        return baseExp + volumeBonus
    }

    private func icon(for exercise: String) -> String {
        if exercise.contains("bench") { return "barbell" }
        if exercise.contains("squat") { return "figure.strengthtraining.traditional" }
        if exercise.contains("deadlift") { return "figure.strengthtraining.functional" }
        return "bolt.heart"
    }
}

private struct MetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct WorkoutSetRow: View {
    let set: WorkoutSet
    let index: Int

    var body: some View {
        HStack(spacing: 16) {
            Text(String(format: "#%d", index))
                .font(.subheadline.weight(.medium))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(set.exercise ?? "Exercise")
                    .font(.subheadline.weight(.semibold))
                Text(String(format: "%.0f kg • %d × %d @ RPE %d", set.weight, set.sets, set.reps, set.rpe))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

// MARK: - Programs

private struct ProgramsYouFollowSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Programs you follow")
                    .font(.headline)
                Spacer()
                Button {
                    // future settings hook
                } label: {
                    Label("Manage", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 16) {
                ProgramCard(
                    title: "PPL Strength",
                    subtitle: "5 day split • Week 7",
                    tags: ["Push", "Pull", "Legs"],
                    progress: 0.68,
                    accent: .blue
                )

                ProgramCard(
                    title: "Hypertrophy Builder",
                    subtitle: "Upper/Lower • Week 3",
                    tags: ["Upper", "Lower"],
                    progress: 0.42,
                    accent: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct ProgramCard: View {
    let title: String
    let subtitle: String
    let tags: [String]
    let progress: CGFloat
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProgressRing(progress: progress, accent: accent)
                    .frame(width: 54, height: 54)
            }

            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(accent.opacity(0.18))
                        )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProgressRing: View {
    let progress: CGFloat
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accent, accent.opacity(0.4), accent]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f%%", min(progress, 1) * 100))
                .font(.caption.weight(.semibold))
        }
    }
}

// MARK: - Recent sessions

private struct RecentSessionsSection: View {
    let workouts: [Workout]
    let calculateVolume: (Workout) -> Double
    let calculateXP: (Workout) -> Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent sessions")
                .font(.headline)

            if workouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Log your first lift to see it here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            } else {
                ForEach(workouts.prefix(5)) { workout in
                    RecentWorkoutRow(
                        workout: workout,
                        volume: calculateVolume(workout),
                        xp: calculateXP(workout)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

private struct RecentWorkoutRow: View {
    let workout: Workout
    let volume: Double
    let xp: Int

    private var setsCount: Int {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return 0 }
        return sets.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title ?? "Workout")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 8) {
                        if let date = workout.date {
                            Label {
                                Text(date, style: .date)
                            } icon: {
                                Image(systemName: "calendar")
                            }
                        }
                        Label("\(setsCount) sets", systemImage: "square.grid.3x2.fill")
                        Label(String(format: "%.0f kg", volume), systemImage: "dumbbell.fill")
                        Label("+\(xp) XP", systemImage: "bolt.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.tertiaryLabel)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Supporting models

private enum LiftHistoryRange: String, CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays
    case ninetyDays

    var id: String { rawValue }

    var lengthInDays: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }

    var shortLabel: String {
        switch self {
        case .sevenDays: return "7D"
        case .thirtyDays: return "30D"
        case .ninetyDays: return "90D"
        }
    }

    var subtitle: String {
        switch self {
        case .sevenDays: return "The last 7 days"
        case .thirtyDays: return "The last 30 days"
        case .ninetyDays: return "The last 90 days"
        }
    }
}

private struct LiftTrendPoint: Identifiable {
    let date: Date
    let totalVolume: Double

    var id: Date { date }
}

private struct LiftOverviewMetrics {
    let metrics: [LiftMetric]

    static func make(current: LiftOverviewMetricsSnapshot, previous: LiftOverviewMetricsSnapshot?) -> LiftOverviewMetrics {
        var tiles: [LiftMetric] = []

        tiles.append(
            LiftMetric(
                title: "Workouts",
                value: "\(current.workouts)",
                icon: "figure.strengthtraining.traditional",
                delta: deltaText(current: current.workouts, previous: previous?.workouts)
            )
        )

        tiles.append(
            LiftMetric(
                title: "Volume",
                value: String(format: "%.0f kg", current.volume),
                icon: "chart.bar.fill",
                delta: deltaText(current: current.volume, previous: previous?.volume)
            )
        )

        let averageDuration = current.workouts == 0 ? 0 : current.duration / current.workouts
        tiles.append(
            LiftMetric(
                title: "Avg session",
                value: "\(averageDuration) min",
                icon: "stopwatch.fill",
                delta: deltaText(current: averageDuration, previous: previous.map { snapshot in
                    snapshot.workouts == 0 ? 0 : snapshot.duration / snapshot.workouts
                })
            )
        )

        tiles.append(
            LiftMetric(
                title: "Top lift",
                value: String(format: "%.0f kg", current.heaviest),
                icon: "barbell",
                delta: nil
            )
        )

        return LiftOverviewMetrics(metrics: tiles)
    }

    private static func deltaText(current: Int, previous: Int?) -> String? {
        guard let previous else { return nil }
        let difference = current - previous
        if difference == 0 { return "No change" }
        return difference > 0 ? "+\(difference) vs last" : "\(difference) vs last"
    }

    private static func deltaText(current: Double, previous: Double?) -> String? {
        guard let previous else { return nil }
        let difference = current - previous
        if abs(difference) < 1 { return "No change" }
        return difference > 0 ? String(format: "+%.0f vs last", difference) : String(format: "%.0f vs last", difference)
    }
}

private struct LiftOverviewMetricsSnapshot {
    let workouts: Int
    let volume: Double
    let sets: Int
    let heaviest: Double
    let duration: Int

    static func capture(from workouts: [Workout]) -> LiftOverviewMetricsSnapshot {
        let totalVolume = workouts.reduce(0.0) { partial, workout in
            partial + LiftOverviewMetricsSnapshot.workoutVolume(workout)
        }
        let totalWorkouts = workouts.count
        let totalSets = workouts.reduce(0) { partial, workout in
            partial + Int((workout.sets as? Set<WorkoutSet>)?.count ?? 0)
        }
        let heaviest = workouts.compactMap { workout -> Double? in
            guard let sets = workout.sets as? Set<WorkoutSet> else { return nil }
            return sets.map { Double($0.weight) }.max()
        }.max() ?? 0
        let duration = workouts.reduce(0) { $0 + Int($1.duration) }
        return LiftOverviewMetricsSnapshot(
            workouts: totalWorkouts,
            volume: totalVolume,
            sets: totalSets,
            heaviest: heaviest,
            duration: duration
        )
    }

    private static func workoutVolume(_ workout: Workout) -> Double {
        guard let sets = workout.sets as? Set<WorkoutSet> else { return 0 }
        return sets.reduce(0.0) { $0 + ($1.weight * Double($1.sets) * Double($1.reps)) }
    }
}

private struct LiftMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let delta: String?

    var deltaText: String? { delta }
}

private struct LiftGoal: Identifiable {
    let id = UUID()
    let name: String
    let goal: Double
    let unit: String
    let accent: Color
    var current: Double = 0

    var progress: Double { goal == 0 ? 0 : current / goal }

    var subtitle: String {
        if goal == 0 { return "Set a goal" }
        let percent = Int(min(progress, 1) * 100)
        return "\(percent)% to goal"
    }

    func with(current: Double) -> LiftGoal {
        var copy = self
        copy.current = current
        return copy
    }
}

private struct SparklineView: View {
    let points: [LiftTrendPoint]
    let accent: Color

    private var maxVolume: Double {
        max(points.map(\.totalVolume).max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard let first = points.first else { return }

                let minTime = first.date.timeIntervalSinceReferenceDate
                let maxTime = points.last?.date.timeIntervalSinceReferenceDate ?? minTime + 1
                let timeSpan = max(maxTime - minTime, 1)

                for (index, point) in points.enumerated() {
                    let xRatio = (point.date.timeIntervalSinceReferenceDate - minTime) / timeSpan
                    let yRatio = maxVolume == 0 ? 0 : point.totalVolume / maxVolume
                    let x = xRatio * geometry.size.width
                    let y = geometry.size.height - (yRatio * geometry.size.height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .shadow(color: accent.opacity(0.35), radius: 8, x: 0, y: 6)
        }
    }
}

private extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        return self.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
}

// MARK: - Existing logging sheets

struct NewWorkoutSheet: View {
    @ObservedObject var gymManager: GymManager
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var sets: [(exercise: String, sets: Int, reps: Int, weight: Double, rpe: Int)] = []
    @State private var showAddSet = false
    @State private var duration = 30

    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    TextField("Workout name", text: $title)
                    Stepper("Duration: \(duration) min", value: $duration, in: 5...180, step: 5)
                }

                Section("Exercises") {
                    ForEach(sets.indices, id: \.self) { index in
                        SetRow(set: sets[index])
                    }

                    Button(action: { showAddSet = true }) {
                        Label("Add Exercise", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Log workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        let workout = gymManager.createWorkout(title: title, sets: sets)
                        gymManager.finishWorkout(workout, duration: duration, gameManager: gameManager)
                        dismiss()
                    }
                    .disabled(title.isEmpty || sets.isEmpty)
                }
            }
            .sheet(isPresented: $showAddSet) {
                AddSetSheet(sets: $sets)
            }
        }
    }
}

struct SetRow: View {
    let set: (exercise: String, sets: Int, reps: Int, weight: Double, rpe: Int)

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(set.exercise)
                .font(.headline)
            Text("\(set.sets) × \(set.reps) @ \(String(format: "%.1f", set.weight))kg • RPE \(set.rpe)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AddSetSheet: View {
    @Binding var sets: [(exercise: String, sets: Int, reps: Int, weight: Double, rpe: Int)]
    @Environment(\.dismiss) var dismiss

    @State private var exercise = ""
    @State private var setCount = 3
    @State private var reps = 10
    @State private var weight = ""
    @State private var rpe = 7

    let exercises = ["Squat", "Bench Press", "Deadlift", "Overhead Press", "Row", "Pull-up", "Leg Press", "Custom"]

    var body: some View {
        NavigationView {
            Form {
                Section("Exercise") {
                    Picker("Exercise", selection: $exercise) {
                        ForEach(exercises, id: \.self) { ex in
                            Text(ex).tag(ex)
                        }
                    }
                }

                Section("Details") {
                    Stepper("Sets: \(setCount)", value: $setCount, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...50)
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    Stepper("RPE: \(rpe)", value: $rpe, in: 1...10)
                }
            }
            .navigationTitle("Add exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let w = Double(weight.replacingOccurrences(of: ",", with: ".")), !exercise.isEmpty {
                            sets.append((exercise, setCount, reps, w, rpe))
                            dismiss()
                        }
                    }
                    .disabled(exercise.isEmpty || weight.isEmpty)
                }
            }
        }
        .onAppear {
            if exercise.isEmpty {
                exercise = exercises.first ?? ""
            }
        }
    }
}
