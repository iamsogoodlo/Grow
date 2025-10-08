import SwiftUI

enum AppModule: CaseIterable, Identifiable {
    case yuka
    case strava
    case myFitnessPal
    case studyBunny
    case habitTracker

    var id: Self { self }

    var title: String {
        switch self {
        case .yuka: return "Yuka"
        case .strava: return "Strava"
        case .myFitnessPal: return "MyFitnessPal"
        case .studyBunny: return "Study Bunny"
        case .habitTracker: return "Habit Tracker"
        }
    }

    var subtitle: String {
        switch self {
        case .yuka: return "Scan foods and auto-log nutrition"
        case .strava: return "Track activities, lifts, and weekly stats"
        case .myFitnessPal: return "Log meals, weight, and XP rewards"
        case .studyBunny: return "Stay focused with timed study sessions"
        case .habitTracker: return "Build routines with streak tracking"
        }
    }

    var icon: String {
        switch self {
        case .yuka: return "barcode.viewfinder"
        case .strava: return "figure.run"
        case .myFitnessPal: return "fork.knife"
        case .studyBunny: return "books.vertical"
        case .habitTracker: return "checkmark.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .yuka: return .green
        case .strava: return .orange
        case .myFitnessPal: return .blue
        case .studyBunny: return .purple
        case .habitTracker: return .mint
        }
    }
}

struct SideMenuView: View {
    let selection: AppModule
    let onSelect: (AppModule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Grow Hub")
                    .font(.largeTitle.weight(.bold))
                Text("All of your wellness tools in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(AppModule.allCases) { module in
                    Button {
                        onSelect(module)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: module.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [module.accentColor.opacity(0.85), module.accentColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.title)
                                    .font(.headline)
                                Text(module.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if module == selection {
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(module == selection ? Color.cardBackground.opacity(0.9) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Need a break?")
                    .font(.headline)
                Text("Switch modules at any time to stay balanced across food, fitness, habits, and focus.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.cardBackground)
            )
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

struct MenuButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.cardBackground.opacity(0.92))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
                )
        }
        .buttonStyle(.plain)
    }
}
