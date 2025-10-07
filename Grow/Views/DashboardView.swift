//
//  DashboardView.swift
//  Grow
//
//  Created by Bryan Liu on 2025-10-07.
//


import SwiftUI

struct DashboardView: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileHeader(gameManager: gameManager)
                
                if let quest = gameManager.weeklyQuest {
                    WeeklyQuestCard(quest: quest)
                }
                
                if !gameManager.activeDebuffs.isEmpty {
                    DebuffBanner(debuffs: gameManager.activeDebuffs, gameManager: gameManager)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Today's Habits")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("\(completedCount)/\(totalCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    ForEach(gameManager.habits.filter { $0.habitType == HabitType.daily.rawValue }) { habit in
                        HabitCard(habit: habit, gameManager: gameManager)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Today")
    }
    
    var completedCount: Int {
        gameManager.todayLogs.filter { $0.completed }.count
    }
    
    var totalCount: Int {
        gameManager.habits.filter { $0.habitType == HabitType.daily.rawValue && $0.mode == HabitMode.good.rawValue }.count
    }
}

struct ProfileHeader: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        if let profile = gameManager.profile {
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(profile.displayName ?? "Player")
                            .font(.title)
                            .bold()
                        
                        HStack(spacing: 8) {
                            Text(PlayerClass(rawValue: profile.playerClass ?? "")?.emoji ?? "")
                            Text("Level \(profile.level)")
                                .font(.headline)
                            
                            if gameManager.skillPoints > 0 {
                                Text("• \(gameManager.skillPoints) SP")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("EXP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(profile.expCurrent)/\(profile.expToNext)")
                            .font(.caption)
                            .bold()
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(profile.expCurrent) / CGFloat(profile.expToNext))
                                .animation(.spring(), value: profile.expCurrent)
                        }
                    }
                    .frame(height: 24)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10)
            )
            .padding(.horizontal)
        }
    }
}

struct WeeklyQuestCard: View {
    let quest: WeeklyQuest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📜")
                    .font(.title2)
                Text("Weekly Quest")
                    .font(.headline)
                Spacer()
                if quest.completed {
                    Text("✅ Complete")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            
            Text(quest.name ?? "Quest")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(quest.progressCount), total: Double(quest.targetCount))
                .tint(.purple)
            
            HStack {
                Text("\(quest.progressCount)/\(quest.targetCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("🎁 Reward: +1% EXP")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.purple.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct DebuffBanner: View {
    let debuffs: [Debuff]
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚠️ Active Penalties")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(debuffs, id: \.id) { debuff in
                HStack {
                    Text(debuff.key ?? "")
                        .font(.subheadline)
                    Spacer()
                    Text("-\(Int(debuff.expReduction * 100))% EXP")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.red.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct HabitCard: View {
    let habit: Habit
    @ObservedObject var gameManager: GameManager
    @State private var showQuantitySheet = false
    @State private var quantityValue: Double = 0
    
    var isCompleted: Bool {
        gameManager.todayLogs.contains { $0.habit == habit && $0.completed }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            if habit.scalar == ScalarType.binary.rawValue {
                Button(action: {
                    if !isCompleted && habit.mode == HabitMode.good.rawValue {
                        gameManager.completeHabit(habit: habit)
                    }
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 32))
                        .foregroundColor(isCompleted ? .green : .gray)
                }
                .disabled(isCompleted && habit.mode == HabitMode.good.rawValue)
            } else {
                Button(action: {
                    if !isCompleted {
                        showQuantitySheet = true
                    }
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(isCompleted ? .green : .blue)
                }
                .disabled(isCompleted)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(habit.name ?? "Habit")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    if habit.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Text("🔥")
                            Text("\(habit.currentStreak)")
                                .font(.caption)
                                .bold()
                        }
                    }
                    
                    HStack(spacing: 3) {
                        Text("⚡️")
                        Text("\(habit.baseExp)")
                            .font(.caption)
                    }
                    
                    if habit.scalar == ScalarType.quantity.rawValue {
                        Text("Target: \(Int(habit.targetNumber))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if habit.mode == HabitMode.bad.rawValue {
                Button(action: {
                    gameManager.logBadHabit(habit: habit)
                }) {
                    Text("Slip")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showQuantitySheet) {
            QuantityInputSheet(
                habit: habit,
                value: $quantityValue,
                onSubmit: {
                    gameManager.completeHabit(habit: habit, value: quantityValue)
                    showQuantitySheet = false
                }
            )
        }
    }
}

struct QuantityInputSheet: View {
    let habit: Habit
    @Binding var value: Double
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text(habit.name ?? "Habit")
                        .font(.title2)
                        .bold()
                    
                    Text("Target: \(Int(habit.targetNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    TextField("0", value: $value, format: .number)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 60, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(height: 80)
                    
                    Divider()
                        .padding(.horizontal, 40)
                }
                
                Button(action: onSubmit) {
                    Text("Complete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(value > 0 ? Color.blue : Color.gray)
                        .cornerRadius(15)
                }
                .disabled(value <= 0)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
}
