import SwiftUI

struct OnboardingView: View {
    @ObservedObject var gameManager: GameManager
    @State private var currentPage = 0
    @State private var name = ""
    @State private var selectedClass: PlayerClass = .warrior
    @State private var selectedHabits: Set<String> = []
    @State private var questName = "Complete 3 Workouts"
    
    let starterHabits = [
        ("💧", "Drink 8 cups water", HabitMode.good, 30, ScalarType.quantity, 8.0),
        ("🏃", "Move 30 minutes", HabitMode.good, 30, ScalarType.binary, 1.0),
        ("😴", "Sleep ≥7 hours", HabitMode.good, 30, ScalarType.binary, 1.0),
        ("🥗", "Hit protein target", HabitMode.good, 35, ScalarType.quantity, 150.0),
        ("📖", "Read 20 pages", HabitMode.good, 25, ScalarType.quantity, 20.0),
        ("🧘", "Meditate 10 min", HabitMode.good, 25, ScalarType.binary, 1.0),
        ("📱", "Phone <60m in bed", HabitMode.bad, 25, ScalarType.binary, 1.0),
        ("🍭", "Avoid added sugar", HabitMode.bad, 20, ScalarType.binary, 1.0)
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                nameClassPage.tag(1)
                habitsPage.tag(2)
                questPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
    
    var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("⚔️")
                .font(.system(size: 100))
            
            Text("Grow")
                .font(.system(size: 50, weight: .bold))
            
            Text("Level up your life,\none habit at a time")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { withAnimation { currentPage = 1 } }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    var nameClassPage: some View {
        VStack(spacing: 30) {
            Text("Create Your Hero")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Your Name")
                    .font(.headline)
                
                TextField("Enter your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Text("Choose Your Class")
                    .font(.headline)
                    .padding(.top)
                
                HStack(spacing: 15) {
                    ForEach(PlayerClass.allCases, id: \.self) { pClass in
                        ClassButton(
                            playerClass: pClass,
                            isSelected: selectedClass == pClass
                        ) {
                            selectedClass = pClass
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: { withAnimation { currentPage = 2 } }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
            }
            .disabled(name.isEmpty)
        }
        .padding()
    }
    
    var habitsPage: some View {
        VStack(spacing: 20) {
            Text("Pick Your Habits")
                .font(.largeTitle)
                .bold()
            
            Text("Select 4-6 habits to start")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(starterHabits, id: \.1) { habit in
                        HabitCheckbox(
                            emoji: habit.0,
                            name: habit.1,
                            mode: habit.2,
                            isSelected: selectedHabits.contains(habit.1)
                        ) {
                            if selectedHabits.contains(habit.1) {
                                selectedHabits.remove(habit.1)
                            } else {
                                selectedHabits.insert(habit.1)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: { withAnimation { currentPage = 3 } }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedHabits.count >= 4 ? Color.blue : Color.gray)
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
            }
            .disabled(selectedHabits.count < 4)
        }
        .padding()
    }
    
    var questPage: some View {
        VStack(spacing: 30) {
            Text("Weekly Quest")
                .font(.largeTitle)
                .bold()
            
            Text("Set a weekly goal to earn bonus rewards")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                Text("📜")
                    .font(.system(size: 80))
                
                TextField("Quest name", text: $questName)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Complete this quest to unlock a reward chest with permanent bonuses!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: createProfile) {
                Text("Start Your Journey")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }
    
    private func createProfile() {
        let context = gameManager.context
        
        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.displayName = name
        profile.playerClass = selectedClass.rawValue
        profile.createdAt = Date()
        profile.level = 1
        profile.expCurrent = 0
        profile.expToNext = 200
        profile.permExpMultiplier = 0
        profile.streakShieldAvailable = true
        profile.cleansesAvailable = 1
        
        for habitData in starterHabits where selectedHabits.contains(habitData.1) {
            let habit = Habit(context: context)
            habit.id = UUID()
            habit.name = habitData.1
            habit.habitType = HabitType.daily.rawValue
            habit.mode = habitData.2.rawValue
            habit.scalar = habitData.4.rawValue
            habit.targetNumber = habitData.5
            habit.baseExp = Int32(habitData.3)
            habit.isActive = true
            habit.createdAt = Date()
            habit.currentStreak = 0
            habit.bestStreak = 0
        }
        
        let quest = WeeklyQuest(context: context)
        quest.id = UUID()
        let weekStart = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        quest.weekStartDate = Calendar.current.date(from: weekStart)!
        quest.name = questName
        quest.targetCount = 3
        quest.progressCount = 0
        quest.completed = false
        
        try? context.save()
        gameManager.loadData()
    }
}

struct ClassButton: View {
    let playerClass: PlayerClass
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(playerClass.emoji)
                    .font(.system(size: 50))
                Text(playerClass.rawValue)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? playerClass.color.opacity(0.3) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? playerClass.color : Color.clear, lineWidth: 3)
            )
        }
    }
}

struct HabitCheckbox: View {
    let emoji: String
    let name: String
    let mode: HabitMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(emoji)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(mode == .good ? "Good Habit" : "Bad Habit")
                        .font(.caption)
                        .foregroundColor(mode == .good ? .green : .red)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}
