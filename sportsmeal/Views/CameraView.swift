import SwiftUI
import SwiftData
import PhotosUI

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealTemplate.useCount, order: .reverse) private var templates: [MealTemplate]
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var estimationResult: CalorieEstimationResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingSaveConfirmation = false
    @State private var portionPercent = 100.0
    @State private var mealNotes = ""
    @State private var selectedCuisine = ""
    @State private var showOptions = false
    @State private var showQuickLog = false
    @State private var analysisTask: Task<Void, Never>?
    @State private var editingFoodIndex: Int?
    @State private var editCaloriesText = ""
    @State private var showingAddFood = false
    @State private var newFoodName = ""
    @State private var newFoodCalories = ""

    private let service = CalorieEstimationService()

    private let portionPresets: [Int] = [25, 50, 75, 100]

    private let cuisineOptions = ["", "Chinese", "Japanese", "Korean", "Indian", "Thai", "Mexican", "Italian", "American", "Mediterranean", "Other"]

    var body: some View {
        NavigationStack {
            if !APIConfig.hasAPIKey {
                apiKeyPrompt
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Quick Log toggle
                        if !templates.isEmpty {
                            quickLogSection
                        }

                        if !showQuickLog {
                            photoSelectionArea
                        }

                        // Meal options — shown after photo selected, before analysis
                        if capturedImage != nil && estimationResult == nil && !isAnalyzing {
                            mealOptionsPanel
                        }

                        if isAnalyzing {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(AppTheme.gold)
                                Text("Analyzing your meal...")
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

                        if let result = estimationResult {
                            resultView(result)
                        }
                    }
                    .padding()
                }
                .background(AppTheme.background)
                .navigationTitle("Scan Meal")
                .onDisappear { analysisTask?.cancel() }
                .toolbar {
                    ToolbarItem(placement: .secondaryAction) {
                        NavigationLink {
                            BarcodeScannerView()
                        } label: {
                            Label("Barcode Scanner", systemImage: "barcode.viewfinder")
                        }
                    }
                    ToolbarItem(placement: .secondaryAction) {
                        NavigationLink {
                            MenuScannerView()
                        } label: {
                            Label("Menu Scanner", systemImage: "menucard")
                        }
                    }
                }
            }
        }
    }

    // MARK: - API Key Prompt
    private var apiKeyPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.goldSubtle)
                    .frame(width: 80, height: 80)
                Image(systemName: "key.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.gold)
            }

            Text("API Key Required")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("To analyze meal photos, set up your own Anthropic API key first. SportsMeal does not include AI usage for you.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink {
                APIKeySettingsView()
            } label: {
                Text("Set Up API Key")
                    .luxuryButton()
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .background(AppTheme.background)
        .navigationTitle("Scan Meal")
    }

    // MARK: - Photo Selection
    private var photoSelectionArea: some View {
        VStack(spacing: 12) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Different Photo", systemImage: "photo.on.rectangle")
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
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(AppTheme.gold)
                        }
                        Text("Tap to select a meal photo")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Choose from your photo library")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .luxuryCard(padding: 24)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                await loadPhoto(item: newValue)
            }
        }
    }

    // MARK: - Result
    private func resultView(_ result: CalorieEstimationResult) -> some View {
        let editedTotal = result.foods.reduce(0) { $0 + $1.calories }

        return VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Estimated Calories")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textTertiary)
                Text("\(Int(editedTotal))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.gold)
                Text("kcal")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)

                let totalP = result.foods.compactMap(\.proteinGrams).reduce(0, +)
                let totalC = result.foods.compactMap(\.carbsGrams).reduce(0, +)
                let totalF = result.foods.compactMap(\.fatGrams).reduce(0, +)
                if totalP + totalC + totalF > 0 {
                    HStack(spacing: 16) {
                        MacroPill(label: "Protein", value: totalP, color: AppTheme.positive)
                        MacroPill(label: "Carbs", value: totalC, color: AppTheme.gold)
                        MacroPill(label: "Fat", value: totalF, color: AppTheme.warning)
                    }
                }

                if let score = result.healthScore {
                    HealthScoreBar(score: score)
                }
            }
            .frame(maxWidth: .infinity)
            .luxuryCard(padding: 20)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Food Items")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("Tap to edit")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                ForEach(Array(result.foods.enumerated()), id: \.offset) { index, food in
                    VStack(spacing: 4) {
                        HStack {
                            // Remove button
                            if result.foods.count > 1 {
                                Button {
                                    removeFood(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.negative.opacity(0.7))
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(food.portionSize)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            Spacer()
                            if editingFoodIndex == index {
                                HStack(spacing: 4) {
                                    TextField("kcal", text: $editCaloriesText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 60)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.surfaceLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Button {
                                        applyCalorieEdit(index: index)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.positive)
                                    }
                                }
                            } else {
                                Button {
                                    editingFoodIndex = index
                                    editCaloriesText = "\(Int(food.calories))"
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("\(Int(food.calories))")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.gold)
                                        Text("kcal")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textTertiary)
                                        Image(systemName: "pencil")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.textTertiary)
                                    }
                                }
                            }
                        }
                        if let p = food.proteinGrams, let c = food.carbsGrams, let f = food.fatGrams {
                            HStack(spacing: 12) {
                                MacroPill(label: "P", value: p, color: AppTheme.positive)
                                MacroPill(label: "C", value: c, color: AppTheme.gold)
                                MacroPill(label: "F", value: f, color: AppTheme.warning)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    Divider().overlay(AppTheme.border)
                }

                // Add food item
                if showingAddFood {
                    VStack(spacing: 8) {
                        TextField("Food name", text: $newFoodName)
                            .font(.subheadline)
                            .padding(8)
                            .background(AppTheme.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        HStack {
                            TextField("Calories", text: $newFoodCalories)
                                .keyboardType(.numberPad)
                                .font(.subheadline)
                                .padding(8)
                                .background(AppTheme.surfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Button {
                                addFood()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.positive)
                                    .font(.title3)
                            }
                            .disabled(newFoodName.isEmpty || newFoodCalories.isEmpty)
                            Button {
                                showingAddFood = false
                                newFoodName = ""
                                newFoodCalories = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .font(.title3)
                            }
                        }
                    }
                    .padding(.top, 4)
                } else {
                    Button {
                        showingAddFood = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add missing item")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                    }
                    .padding(.top, 4)
                }
            }
            .luxuryCard()

            Button { saveMeal(result) } label: {
                Label("Save Meal", systemImage: "checkmark.circle.fill")
                    .luxuryButton()
            }

            if showingSaveConfirmation {
                Label("Meal saved!", systemImage: "checkmark")
                    .foregroundStyle(AppTheme.positive)
                    .transition(.opacity)
            }
        }
    }

    private func applyCalorieEdit(index: Int) {
        guard let result = estimationResult,
              let newCal = Double(editCaloriesText),
              index < result.foods.count else { return }
        var food = result.foods[index]
        food = EstimatedFood(
            name: food.name,
            calories: newCal,
            portionSize: food.portionSize,
            proteinGrams: food.proteinGrams,
            carbsGrams: food.carbsGrams,
            fatGrams: food.fatGrams
        )
        var foods = result.foods
        foods[index] = food
        let newTotal = foods.reduce(0) { $0 + $1.calories }
        estimationResult = CalorieEstimationResult(
            foods: foods,
            totalCalories: newTotal,
            healthScore: result.healthScore
        )
        editingFoodIndex = nil
    }

    private func removeFood(at index: Int) {
        guard let result = estimationResult, index < result.foods.count else { return }
        var foods = result.foods
        foods.remove(at: index)
        let newTotal = foods.reduce(0) { $0 + $1.calories }
        withAnimation {
            estimationResult = CalorieEstimationResult(
                foods: foods,
                totalCalories: newTotal,
                healthScore: result.healthScore
            )
        }
        if editingFoodIndex == index { editingFoodIndex = nil }
    }

    private func addFood() {
        guard let result = estimationResult,
              !newFoodName.isEmpty,
              let cal = Double(newFoodCalories) else { return }
        let newFood = EstimatedFood(
            name: newFoodName,
            calories: cal,
            portionSize: "",
            proteinGrams: nil,
            carbsGrams: nil,
            fatGrams: nil
        )
        var foods = result.foods
        foods.append(newFood)
        let newTotal = foods.reduce(0) { $0 + $1.calories }
        withAnimation {
            estimationResult = CalorieEstimationResult(
                foods: foods,
                totalCalories: newTotal,
                healthScore: result.healthScore
            )
        }
        newFoodName = ""
        newFoodCalories = ""
        showingAddFood = false
    }

    // MARK: - Meal Options
    private var mealOptionsPanel: some View {
        VStack(spacing: 14) {
            // How much did you eat?
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("How much did you eat?")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(portionPercent))%")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.gold)
                }

                Slider(value: $portionPercent, in: 5...100, step: 5)
                    .tint(AppTheme.gold)

                HStack(spacing: 8) {
                    ForEach(portionPresets, id: \.self) { pct in
                        Button {
                            portionPercent = Double(pct)
                        } label: {
                            Text("\(pct)%")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Int(portionPercent) == pct ? AppTheme.gold : AppTheme.surfaceLight)
                                .foregroundStyle(Int(portionPercent) == pct ? .black : AppTheme.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            // Cuisine picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Cuisine (optional)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(cuisineOptions, id: \.self) { cuisine in
                            let label = cuisine.isEmpty ? "Auto" : cuisine
                            Button {
                                selectedCuisine = cuisine
                            } label: {
                                Text(label)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCuisine == cuisine ? AppTheme.gold : AppTheme.surfaceLight)
                                    .foregroundStyle(selectedCuisine == cuisine ? .black : AppTheme.textSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (optional)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("e.g., 外卖/少油/shared plate/half eaten", text: $mealNotes)
                    .font(.subheadline)
                    .padding(10)
                    .background(AppTheme.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Analyze button
            Button {
                analysisTask = Task { await analyzeCurrentPhoto() }
            } label: {
                Label("Analyze Meal", systemImage: "sparkles")
                    .luxuryButton()
            }
        }
        .luxuryCard()
    }

    // MARK: - Logic
    private func loadPhoto(item: PhotosPickerItem?) async {
        guard let item else { return }
        errorMessage = nil
        estimationResult = nil
        showingSaveConfirmation = false
        // Reset options for new photo
        portionPercent = 100.0
        mealNotes = ""
        selectedCuisine = ""

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load the selected photo"
                return
            }
            capturedImage = image
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyzeCurrentPhoto() async {
        guard let image = capturedImage else { return }
        errorMessage = nil
        isAnalyzing = true

        do {
            let result = try await service.estimateCalories(
                from: image,
                portionMultiplier: portionPercent / 100.0,
                notes: mealNotes.isEmpty ? nil : mealNotes,
                cuisine: selectedCuisine.isEmpty ? nil : selectedCuisine
            )
            estimationResult = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }

    private func saveMeal(_ result: CalorieEstimationResult) {
        let foodItems = result.foods.map { food in
            FoodItem(name: food.name, calories: food.calories, portionSize: food.portionSize,
                     proteinGrams: food.proteinGrams, carbsGrams: food.carbsGrams, fatGrams: food.fatGrams)
        }
        let meal = Meal(
            photoData: capturedImage?.jpegData(compressionQuality: 0.7),
            foodItems: foodItems,
            totalCalories: result.totalCalories,
            timestamp: Date(),
            notes: mealNotes,
            cuisineType: selectedCuisine,
            portionMultiplier: portionPercent / 100.0
        )
        modelContext.insert(meal)
        withAnimation { showingSaveConfirmation = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            capturedImage = nil
            estimationResult = nil
            selectedPhoto = nil
            showingSaveConfirmation = false
        }
    }

    // MARK: - Quick Log
    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    withAnimation { showQuickLog.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(AppTheme.gold)
                        Text("Quick Log")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: showQuickLog ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            if showQuickLog {
                let suggested = MealTemplate.suggestedCategory()
                Text("Suggested for \(suggested.lowercased())")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)

                ForEach(templates) { template in
                    Button {
                        logFromTemplate(template)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(template.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text("\(template.foodItems.count) items")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(template.totalCalories))")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.gold)
                                Text("kcal")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                        }
                        .luxuryCard()
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(template)
                        } label: {
                            Label("Delete Template", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .luxuryCard()
    }

    private func logFromTemplate(_ template: MealTemplate) {
        let meal = Meal(
            foodItems: template.foodItems,
            totalCalories: template.totalCalories,
            timestamp: Date()
        )
        modelContext.insert(meal)
        template.useCount += 1
        template.lastUsed = Date()

        withAnimation { showingSaveConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaveConfirmation = false
        }
    }
}

// MARK: - Health Score Bar
struct HealthScoreBar: View {
    let score: Int

    private var scoreColor: Color {
        switch score {
        case 1...3: return AppTheme.negative
        case 4...5: return AppTheme.warning
        case 6...7: return AppTheme.gold
        case 8...10: return AppTheme.positive
        default: return AppTheme.textTertiary
        }
    }

    private var scoreLabel: String {
        switch score {
        case 1...3: return String(localized: "Unhealthy")
        case 4...5: return String(localized: "Below Average")
        case 6...7: return String(localized: "Decent")
        case 8...9: return String(localized: "Healthy")
        case 10: return String(localized: "Excellent")
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(scoreColor)
                Text("Health Score")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text("\(score) / 10")
                    .font(.caption.bold())
                    .foregroundStyle(scoreColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.surfaceLight)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor)
                        .frame(width: geo.size.width * CGFloat(score) / 10.0, height: 6)
                }
            }
            .frame(height: 6)

            Text(scoreLabel)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health score: \(score) out of 10, \(scoreLabel)")
    }
}

// MARK: - Macro Pill
struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}

#Preview {
    CameraView()
        .modelContainer(for: Meal.self, inMemory: true)
        .preferredColorScheme(.dark)
}
