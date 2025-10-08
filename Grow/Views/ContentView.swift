import SwiftUI

struct ContentView: View {
    @StateObject private var gameManager: GameManager
    @StateObject private var nutritionManager: NutritionManager
    @StateObject private var gymManager: GymManager
    @State private var selectedModule: AppModule = .yuka
    @State private var isMenuVisible = false

    init() {
        let context = PersistenceController.shared.container.viewContext
        _gameManager = StateObject(wrappedValue: GameManager(context: context))
        _nutritionManager = StateObject(wrappedValue: NutritionManager(context: context))
        _gymManager = StateObject(wrappedValue: GymManager(context: context))
    }
    
    var body: some View {
        Group {
            if gameManager.profile == nil {
                OnboardingView(gameManager: gameManager)
            } else {
                ZStack(alignment: .leading) {
                    activeModuleView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay {
                            if isMenuVisible {
                                Color.black.opacity(0.35)
                                    .ignoresSafeArea()
                                    .onTapGesture { toggleMenu() }
                            }
                        }
                        .disabled(isMenuVisible)
                        .animation(.easeInOut(duration: 0.2), value: isMenuVisible)

                    SideMenuView(
                        selection: selectedModule,
                        onSelect: { module in
                            selectedModule = module
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                isMenuVisible = false
                            }
                        }
                    )
                    .frame(width: 280)
                    .offset(x: isMenuVisible ? 0 : -320)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isMenuVisible)
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

    private func toggleMenu() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isMenuVisible.toggle()
        }
    }

    @ViewBuilder
    private var activeModuleView: some View {
        switch selectedModule {
        case .yuka:
            YukaScannerView(
                nutritionManager: nutritionManager,
                gameManager: gameManager,
                onMenuToggle: toggleMenu
            )
        case .strava:
            StravaHubView(
                gymManager: gymManager,
                gameManager: gameManager,
                profile: gameManager.profile,
                onMenuToggle: toggleMenu
            )
        case .myFitnessPal:
            NutritionView(
                nutritionManager: nutritionManager,
                profile: gameManager.profile,
                gameManager: gameManager,
                onMenuToggle: toggleMenu
            )
        case .studyBunny:
            StudyTrackerView(onMenuToggle: toggleMenu)
        case .habitTracker:
            HabitTrackerView(onMenuToggle: toggleMenu)
        }
    }
}
