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

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(AppTheme.gold)
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if profiles.isEmpty && !hasCompletedOnboarding {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        } else {
            MainTabView()
        }
    }
}
