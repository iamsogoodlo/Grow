import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var gameManager: GameManager
    @State private var selectedTab = 0
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _gameManager = StateObject(wrappedValue: GameManager(context: context))
    }
    
    var body: some View {
        Group {
            if gameManager.profile == nil {
                OnboardingView(gameManager: gameManager)
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView(gameManager: gameManager)
                        .tabItem {
                            Label("Today", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    Text("Progress")
                        .tabItem {
                            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(1)
                    
                    Text("Skills")
                        .tabItem {
                            Label("Skills", systemImage: "star.fill")
                        }
                        .tag(2)
                }
                .overlay(alignment: .bottom) {
                    if gameManager.showUndoSnackbar {
                        UndoSnackbar(gameManager: gameManager)
                            .transition(.move(edge: .bottom))
                            .animation(.spring(), value: gameManager.showUndoSnackbar)
                    }
                }
                .sheet(isPresented: $gameManager.showLevelUpModal) {
                    LevelUpModal(gameManager: gameManager)
                }
                .sheet(isPresented: $gameManager.showChestModal) {
                    ChestModal(gameManager: gameManager)
                }
            }
        }
    }
}
