import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CameraView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)

            ExerciseView()
                .tabItem {
                    Label("Exercise", systemImage: "figure.run")
                }
                .tag(3)

            PantryView()
                .tabItem {
                    Label("Pantry", systemImage: "refrigerator.fill")
                }
                .tag(4)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(5)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, Meal.self, ExerciseEntry.self, PantryItem.self], inMemory: true)
        .preferredColorScheme(.dark)
}
