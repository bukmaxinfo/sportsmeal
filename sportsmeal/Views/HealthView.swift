import SwiftUI
import HealthKit

struct HealthView: View {
    @StateObject private var healthService = HealthKitService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authorization card
                authorizationCard

                if healthService.isAuthorized {
                    // Weight card
                    metricCard(
                        icon: "scalemass.fill",
                        title: "Latest Weight",
                        value: healthService.latestWeight.map { String(format: "%.1f kg", $0) },
                        accent: AppTheme.gold
                    )

                    // Steps card
                    metricCard(
                        icon: "figure.walk",
                        title: "Today's Steps",
                        value: healthService.todaySteps.map { "\($0.formatted())" },
                        accent: AppTheme.positive
                    )

                    // Active calories card
                    metricCard(
                        icon: "flame.fill",
                        title: "Active Calories",
                        value: healthService.todayActiveCalories.map { String(format: "%.0f kcal", $0) },
                        accent: AppTheme.gold
                    )
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Authorization card

    private var authorizationCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.gold)
                Text("Apple Health")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                statusBadge
            }

            if !healthService.isAuthorized {
                Text("Connect to Apple Health to sync your weight, steps, and activity data.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    healthService.requestAuthorization()
                } label: {
                    Text("Connect to Health")
                        .luxuryButton()
                }
            }
        }
        .luxuryCard()
    }

    // MARK: - Status badge

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(healthService.isAuthorized ? AppTheme.positive : AppTheme.textTertiary)
                .frame(width: 8, height: 8)
            Text(healthService.isAuthorized ? "Connected" : "Not connected")
                .font(.caption)
                .foregroundStyle(healthService.isAuthorized ? AppTheme.positive : AppTheme.textSecondary)
        }
    }

    // MARK: - Metric card

    private func metricCard(icon: String, title: String, value: String?, accent: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value ?? "—")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()
        }
        .luxuryCard()
    }
}

#Preview {
    NavigationStack {
        HealthView()
    }
    .preferredColorScheme(.dark)
}
