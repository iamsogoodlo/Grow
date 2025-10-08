//
//  LeaderboardView.swift
//  Grow
//
//  Created by Bryan Liu on 2025-10-07.
//


import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameManager: GameManager
    @State private var leaderboardType: LeaderboardType = .weekly
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Type Picker
                Picker("Leaderboard Type", selection: $leaderboardType) {
                    Text("This Week").tag(LeaderboardType.weekly)
                    Text("All Time").tag(LeaderboardType.allTime)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No leaderboard data yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Complete habits to appear on the leaderboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(entries) { entry in
                                LeaderboardRow(entry: entry, type: leaderboardType)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                loadLeaderboard()
            }
            .onChange(of: leaderboardType) { oldValue, newValue in
                loadLeaderboard()
            }
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        LeaderboardManager.shared.fetchLeaderboard(type: leaderboardType) { fetchedEntries in
            entries = fetchedEntries
            isLoading = false
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardType
    
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2, 3: return "medal.fill"
        default: return "\(entry.rank).circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank
            Image(systemName: rankIcon)
                .font(.title2)
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(PlayerClass(rawValue: entry.playerClass)?.emoji ?? "")
                    Text("Level \(entry.level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                if type == .weekly {
                    Text("\(entry.weeklyExp) XP")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Text("this week")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(entry.totalExp) XP")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("all time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .shadow(color: .black.opacity(entry.rank <= 3 ? 0.15 : 0.05), radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(entry.rank <= 3 ? rankColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}
