//
//  GymView.swift
//  Grow
//
//  Created by Bryan Liu on 2025-10-07.
//


import SwiftUI

struct GymView: View {
    @ObservedObject var gymManager: GymManager
    @ObservedObject var gameManager: GameManager
    @State private var showNewWorkout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Personal Records
                    PersonalRecordsSection(gymManager: gymManager)
                    
                    // Recent Workouts
                    RecentWorkoutsSection(
                        gymManager: gymManager,
                        showNewWorkout: $showNewWorkout
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Gym")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showNewWorkout = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showNewWorkout) {
                NewWorkoutSheet(gymManager: gymManager, gameManager: gameManager)
            }
        }
    }
}

// MARK: - Personal Records Section

struct PersonalRecordsSection: View {
    @ObservedObject var gymManager: GymManager
    
    var topPRs: [(String, Double)] {
        Array(gymManager.personalRecords.sorted { $0.value > $1.value }.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Personal Records")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            if topPRs.isEmpty {
                Text("Complete workouts to track PRs")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(topPRs, id: \.0) { exercise, oneRM in
                    PRRow(exercise: exercise, oneRM: oneRM)
                }
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

struct PRRow: View {
    let exercise: String
    let oneRM: Double
    
    var body: some View {
        HStack {
            Text("🏆")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.capitalized)
                    .font(.headline)
                Text("1RM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f kg", oneRM))
                .font(.title3)
                .bold()
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - Recent Workouts Section

struct RecentWorkoutsSection: View {
    @ObservedObject var gymManager: GymManager
    @Binding var showNewWorkout: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Workouts")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { showNewWorkout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if gymManager.workouts.isEmpty {
                Text("No workouts yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(gymManager.workouts.prefix(10)) { workout in
                    WorkoutRow(workout: workout)
                }
            }
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var setCount: Int {
        (workout.sets as? Set<WorkoutSet>)?.count ?? 0
    }
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(workout.title ?? "Workout")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    if workout.duration > 0 {
                        Label("\(workout.duration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(setCount) sets", systemImage: "dumbbell")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if workout.expGranted > 0 {
                        Text("+\(workout.expGranted) XP")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            if let date = workout.date {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// MARK: - New Workout Sheet

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
            .navigationTitle("New Workout")
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
                    Stepper("RPE: \(rpe)", value: $rpe, in: 1...10)
                }
            }
            .navigationTitle("Add Set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let w = Double(weight), !exercise.isEmpty {
                            sets.append((exercise, setCount, reps, w, rpe))
                            dismiss()
                        }
                    }
                    .disabled(exercise.isEmpty || weight.isEmpty)
                }
            }
        }
        .onAppear {
            if !exercises.isEmpty {
                exercise = exercises[0]
            }
        }
    }
}
