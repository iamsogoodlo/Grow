import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var gameManager: GameManager
    @StateObject private var nutritionManager: NutritionManager
    @StateObject private var gymManager: GymManager
    @StateObject private var galleryManager: GalleryManager
    @State private var selectedTab = 0
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _gameManager = StateObject(wrappedValue: GameManager(context: context))
        _nutritionManager = StateObject(wrappedValue: NutritionManager(context: context))
        _gymManager = StateObject(wrappedValue: GymManager(context: context))
        _galleryManager = StateObject(wrappedValue: GalleryManager(context: context))
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

                    NutritionView(
                        nutritionManager: nutritionManager,
                        profile: gameManager.profile,
                        gameManager: gameManager
                    )
                    .tabItem {
                        Label("Nutrition", systemImage: "fork.knife")
                    }
                    .tag(1)

                    GymView(gymManager: gymManager, gameManager: gameManager)
                        .tabItem {
                            Label("Gym", systemImage: "dumbbell")
                        }
                        .tag(2)

                    LeaderboardView(gameManager: gameManager)
                        .tabItem {
                            Label("Leaderboard", systemImage: "trophy.fill")
                        }
                        .tag(3)

                    GalleryView(galleryManager: galleryManager)
                        .tabItem {
                            Label("Progress", systemImage: "photo.on.rectangle")
                        }
                        .tag(4)
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
