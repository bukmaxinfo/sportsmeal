import SwiftUI
import SwiftData
import PhotosUI

struct MenuScannerView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]
    @Query(sort: \ExerciseEntry.timestamp, order: .reverse) private var allExercises: [ExerciseEntry]

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var menuImage: UIImage?
    @State private var scanResult: MenuScanResult?
    @State private var isScanning = false
    @State private var errorMessage: String?

    private let service = MenuScannerService()
    private var profile: UserProfile? { profiles.first }

    private var remainingCalories: Int {
        guard let profile = profile else { return 2000 }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let consumed = allMeals.filter { $0.timestamp >= startOfDay }.reduce(0) { $0 + $1.totalCalories }
        let exerciseBurned = allExercises.filter { $0.timestamp >= startOfDay }.reduce(0) { $0 + $1.caloriesBurned(weightKg: profile.weightKg) }
        return Int(profile.bmr + exerciseBurned - consumed)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget reminder
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(AppTheme.gold)
                        Text("\(max(0, remainingCalories)) kcal remaining today")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .luxuryCard()

                    // Photo picker
                    if let image = menuImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose Different Menu", systemImage: "photo.on.rectangle")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.gold)
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.goldSubtle)
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "menucard.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(AppTheme.gold)
                                }
                                Text("Scan a Restaurant Menu")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Take a photo of the menu to see calorie estimates")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .luxuryCard(padding: 24)
                        }
                    }

                    if isScanning {
                        VStack(spacing: 12) {
                            ProgressView().tint(AppTheme.gold)
                            Text("Analyzing menu...")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .luxuryCard(padding: 24)
                    }

                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.negative)
                            .luxuryCard()
                    }

                    if let result = scanResult {
                        dishResults(result)
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Menu Scanner")
            .onChange(of: selectedPhoto) { _, newValue in
                Task { await loadAndScan(item: newValue) }
            }
        }
    }

    private func dishResults(_ result: MenuScanResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !result.restaurantType.isEmpty {
                Text(result.restaurantType)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
            }

            Text("Dishes")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(result.dishes) { dish in
                HStack(spacing: 12) {
                    // Fit indicator
                    Circle()
                        .fill(dish.fitsWithinBudget ? AppTheme.positive : AppTheme.negative)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(dish.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(dish.description)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineLimit(2)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(dish.estimatedCalories)")
                            .font(.subheadline.bold())
                            .foregroundStyle(dish.fitsWithinBudget ? AppTheme.gold : AppTheme.negative)
                        Text("kcal")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .luxuryCard()
            }

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.positive).frame(width: 8, height: 8)
                    Text("Fits your budget").font(.caption2).foregroundStyle(AppTheme.textTertiary)
                }
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.negative).frame(width: 8, height: 8)
                    Text("Over budget").font(.caption2).foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
    }

    private func loadAndScan(item: PhotosPickerItem?) async {
        guard let item else { return }
        errorMessage = nil
        scanResult = nil
        isScanning = true

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load photo"
                isScanning = false
                return
            }
            menuImage = image
            scanResult = try await service.scanMenu(
                image: image,
                remainingCalories: remainingCalories,
                dietaryPreference: profile?.dietarySummary ?? ""
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isScanning = false
    }
}

#Preview {
    MenuScannerView()
        .modelContainer(for: [UserProfile.self, Meal.self, ExerciseEntry.self], inMemory: true)
        .preferredColorScheme(.dark)
}
