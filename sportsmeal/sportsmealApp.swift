//
//  sportsmealApp.swift
//  sportsmeal
//
//  Created by shuming li on 4/5/26.
//

import SwiftUI
import SwiftData

@main
struct sportsmealApp: App {
    @State private var authService = AuthService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Meal.self,
            ExerciseEntry.self,
            PantryItem.self,
            MealTemplate.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Activate WatchConnectivity so the Watch app can send/receive data
        WatchSyncService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .preferredColorScheme(.dark)
                .tint(AppTheme.gold)
                .onAppear {
                    // Give WatchSyncService a context so it can handle incoming Watch messages
                    WatchSyncService.shared.modelContext = sharedModelContainer.mainContext
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            switch authService.authState {
            case .checking:
                splashView
            case .unauthenticated:
                LoginView()
            case .authenticated:
                if profiles.isEmpty && !hasCompletedOnboarding {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                } else {
                    MainTabView()
                }
            }
        }
        .task {
            await authService.checkExistingSession()
        }
    }

    private var splashView: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppTheme.goldSubtle)
                        .frame(width: 90, height: 90)
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.gold)
                }
                ProgressView()
                    .tint(AppTheme.gold)
            }
        }
    }
}
