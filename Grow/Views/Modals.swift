import SwiftUI

struct LevelUpModal: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("⭐️")
                    .font(.system(size: 100))
                    .shadow(color: .yellow, radius: 20)
                
                Text("LEVEL UP!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.yellow)
                
                if let profile = gameManager.profile {
                    Text("Level \(profile.level)")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 10) {
                    Text("🌟 You earned 1 Skill Point!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Visit the Skills tab to unlock new abilities")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Button(action: { dismiss() }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .padding(40)
        }
    }
}

struct ChestModal: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    @State private var showReward = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                if !showReward {
                    Text("🎁")
                        .font(.system(size: 100))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    showReward = true
                                }
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        Text("✨")
                            .font(.system(size: 80))
                        
                        Text("QUEST COMPLETE!")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.purple)
                        
                        VStack(spacing: 15) {
                            RewardRow(icon: "🏆", text: "Random Badge Unlocked")
                            RewardRow(icon: "⚡️", text: "+1% Permanent EXP Bonus")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                if showReward {
                    Button(action: { dismiss() }) {
                        Text("Claim Reward")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .padding(40)
        }
    }
}

struct RewardRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Text(icon)
                .font(.title)
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct UndoSnackbar: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            Text("Action completed")
                .foregroundColor(.white)
                .font(.subheadline)
            
            Spacer()
            
            Button(action: {
                gameManager.undo()
            }) {
                Text("UNDO")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
        )
        .padding()
        .shadow(radius: 10)
    }
}
