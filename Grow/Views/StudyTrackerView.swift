import SwiftUI

struct StudyTrackerView: View {
    let onMenuToggle: () -> Void

    @State private var sessions: [StudySession] = []
    @State private var focusTopic: String = ""
    @State private var plannedDuration: Int = 25
    @State private var showAddSession = false

    private var calendar: Calendar { Calendar.current }

    private var todayMinutes: Int {
        let today = Date()
        return sessions
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.minutes }
    }

    private var weekMinutes: Int {
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) else { return 0 }
        return sessions
            .filter { session in
                session.date >= weekStart
            }
            .reduce(0) { $0 + $1.minutes }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    summaryCard
                    focusPlannerCard
                    sessionHistory
                    tipsCard
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Study Bunny")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MenuButton(action: onMenuToggle)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSession = true
                    } label: {
                        Label("Log Session", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSession) {
                AddStudySessionView { newSession in
                    sessions.insert(newSession, at: 0)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focused progress")
                .font(.headline)
            Text("Stay consistent with your study streak and reward yourself when you hit your targets.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 16) {
                statBlock(title: "Today", value: "\(todayMinutes) min", icon: "sun.max.fill", tint: .orange)
                statBlock(title: "This Week", value: "\(weekMinutes) min", icon: "calendar", tint: .blue)
                statBlock(title: "Sessions", value: "\(sessions.count)", icon: "book", tint: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var focusPlannerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plan a focus sprint")
                .font(.headline)

            TextField("Topic or task", text: $focusTopic)
                .textFieldStyle(.roundedBorder)

            Stepper(value: $plannedDuration, in: 10...90, step: 5) {
                Text("Duration: \(plannedDuration) minutes")
            }

            Button {
                let session = StudySession(
                    topic: focusTopic.isEmpty ? "Focus Session" : focusTopic,
                    minutes: plannedDuration,
                    date: Date(),
                    mood: .motivated
                )
                sessions.insert(session, at: 0)
                focusTopic = ""
                plannedDuration = 25
            } label: {
                Text("Start & Log Session")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.85), .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session History")
                .font(.headline)

            if sessions.isEmpty {
                Text("Log a study sprint to start building your momentum.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sessions) { session in
                        StudySessionRow(session: session) { completed in
                            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                                sessions[index].mood = completed
                            }
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

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Productivity tips")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "timer", title: "Use the Pomodoro technique", description: "Work for 25 minutes, rest for 5, and repeat to maintain focus.")
                TipRow(icon: "moon.stars.fill", title: "End with reflection", description: "Write a short recap of what you learned to improve retention.")
                TipRow(icon: "sparkles", title: "Reward progress", description: "After three sessions in a day, celebrate with a break or small treat.")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)
        )
    }

    private func statBlock(title: String, value: String, icon: String, tint: Color) -> some View {
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
}

private struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
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

private struct StudySessionRow: View {
    let session: StudySession
    let onMoodChange: (StudyMood) -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.topic)
                        .font(.headline)
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(session.minutes) min")
                    .font(.subheadline.weight(.semibold))
            }

            HStack {
                ForEach(StudyMood.allCases) { mood in
                    Button {
                        onMoodChange(mood)
                    } label: {
                        Image(systemName: mood.icon)
                            .font(.subheadline)
                            .foregroundStyle(session.mood == mood ? .white : .secondary)
                            .frame(width: 36, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(session.mood == mood ? Color.purple : Color.cardBackground)
                            )
                    }
                    .buttonStyle(.plain)
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
}

private struct AddStudySessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var topic: String = ""
    @State private var minutes: Int = 30
    @State private var selectedMood: StudyMood = .productive

    let onSave: (StudySession) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Topic", text: $topic)

                    Stepper(value: $minutes, in: 10...240, step: 5) {
                        Text("Duration: \(minutes) minutes")
                    }
                }

                Section("How did it feel?") {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(StudyMood.allCases) { mood in
                            Label(mood.title, systemImage: mood.icon)
                                .tag(mood)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Log Study Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let session = StudySession(
                            topic: topic.isEmpty ? "Study Session" : topic,
                            minutes: minutes,
                            date: Date(),
                            mood: selectedMood
                        )
                        onSave(session)
                        dismiss()
                    }
                    .disabled(topic.isEmpty && minutes == 0)
                }
            }
        }
    }
}

struct StudySession: Identifiable {
    let id = UUID()
    var topic: String
    var minutes: Int
    var date: Date
    var mood: StudyMood
}

enum StudyMood: String, CaseIterable, Identifiable {
    case productive
    case motivated
    case distracted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .productive: return "Productive"
        case .motivated: return "Motivated"
        case .distracted: return "Distracted"
        }
    }

    var icon: String {
        switch self {
        case .productive: return "checkmark.seal.fill"
        case .motivated: return "bolt.heart"
        case .distracted: return "zzz"
        }
    }
}
