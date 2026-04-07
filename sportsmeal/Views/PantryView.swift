import SwiftUI
import SwiftData
import PhotosUI

struct PantryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]
    private var todaysMeals: [Meal] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allMeals.filter { $0.timestamp >= startOfDay }
    }
    @State private var showAddSheet = false
    @State private var showScanSheet = false
    @State private var showRecipes = false
    @State private var recipes: [RecipeSuggestion] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var groupedItems: [(IngredientCategory, [PantryItem])] {
        Dictionary(grouping: pantryItems, by: \.category).sorted { $0.key.rawValue < $1.key.rawValue }
    }
    private var remainingCalories: Int {
        max(0, Int((profiles.first?.bmr ?? 2000) - todaysMeals.reduce(0.0) { $0 + $1.totalCalories }))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerButtons
                    if pantryItems.isEmpty { emptyState } else { pantryList }
                    if showRecipes { recipeSection }
                }.padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Pantry")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddSheet) { AddItemSheet(modelContext: modelContext) }
            .sheet(isPresented: $showScanSheet) { ScanFridgeSheet(modelContext: modelContext) }
            .alert("Error", isPresented: .init(get: { errorMessage != nil },
                                               set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var headerButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button { showAddSheet = true } label: {
                    Label("Add Item", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                }.luxuryButton()
                Button { showScanSheet = true } label: {
                    Label("Scan Fridge", systemImage: "camera.fill").frame(maxWidth: .infinity)
                }.luxuryButton()
            }
            if !pantryItems.isEmpty {
                Button { generateRecipes() } label: {
                    Group {
                        if isGenerating { ProgressView().tint(.black) }
                        else { Label("Generate Recipes (\(remainingCalories) kcal left)", systemImage: "fork.knife") }
                    }.frame(maxWidth: .infinity)
                }.luxuryButton().disabled(isGenerating)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "refrigerator").font(.system(size: 48)).foregroundStyle(AppTheme.textTertiary)
            Text("Your pantry is empty").font(.headline).foregroundStyle(AppTheme.textSecondary)
            Text("Add items manually or scan your fridge").font(.subheadline).foregroundStyle(AppTheme.textTertiary)
        }.frame(maxWidth: .infinity).padding(.vertical, 40).luxuryCard()
    }

    private var pantryList: some View {
        ForEach(groupedItems, id: \.0) { category, items in
            VStack(alignment: .leading, spacing: 8) {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.gold).padding(.leading, 4)
                ForEach(items) { item in pantryRow(item) }
            }.luxuryCard()
        }
    }

    private func pantryRow(_ item: PantryItem) -> some View {
        HStack {
            Image(systemName: item.category.icon)
                .foregroundStyle(item.isExpired ? AppTheme.negative : item.isExpiringSoon ? AppTheme.warning : AppTheme.gold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).foregroundStyle(item.isAvailable ? AppTheme.textPrimary : AppTheme.textTertiary)
                    .strikethrough(!item.isAvailable)
                if !item.quantity.isEmpty {
                    Text(item.quantity).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                if let exp = item.expirationDate {
                    Text(item.isExpired ? "Expired" : "Exp: \(exp, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption2).foregroundStyle(item.isExpired ? AppTheme.negative : item.isExpiringSoon ? AppTheme.warning : AppTheme.textTertiary)
                }
            }
            Spacer()
            if !item.isAvailable { Text("Used").font(.caption2).foregroundStyle(AppTheme.textTertiary) }
        }
        .contentShape(Rectangle())
        .onTapGesture { item.isAvailable.toggle() }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(item) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Suggestions").font(.title3.weight(.semibold)).foregroundStyle(AppTheme.gold)
            ForEach(recipes) { recipe in RecipeCard(recipe: recipe) }
        }
    }

    private func generateRecipes() {
        isGenerating = true
        let ingredients = pantryItems.filter(\.isAvailable).map(\.name)
        let calTarget = remainingCalories
        let diet = profiles.first?.dietarySummary ?? ""
        Task {
            do {
                let result = try await RecipeService().generateRecipes(
                    ingredients: ingredients, calorieTarget: calTarget, dietaryPreference: diet)
                await MainActor.run { recipes = result; showRecipes = true; isGenerating = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isGenerating = false }
            }
        }
    }
}

// MARK: - Recipe Card
private struct RecipeCard: View {
    let recipe: RecipeSuggestion
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.name).font(.headline).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundStyle(AppTheme.textTertiary)
            }.contentShape(Rectangle()).onTapGesture { withAnimation { expanded.toggle() } }
            HStack(spacing: 16) {
                Label("\(recipe.estimatedCalories) kcal", systemImage: "flame.fill").foregroundStyle(AppTheme.warning)
                Label("\(recipe.prepTimeMinutes) min", systemImage: "clock.fill").foregroundStyle(AppTheme.textSecondary)
            }.font(.caption)
            if expanded {
                Divider().background(AppTheme.border)
                Text("Ingredients").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.gold)
                ForEach(recipe.ingredients, id: \.self) { ing in
                    Text("  \u{2022} \(ing)").font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Text("Instructions").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.gold).padding(.top, 4)
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { idx, step in
                    Text("\(idx + 1). \(step)").font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
        }.luxuryCard()
    }
}

// MARK: - Add Item Sheet
private struct AddItemSheet: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: IngredientCategory = .other
    @State private var quantity = ""
    @State private var hasExpiration = false
    @State private var expirationDate = Date().addingTimeInterval(7 * 86400)
    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(IngredientCategory.allCases) { cat in Label(cat.rawValue, systemImage: cat.icon).tag(cat) }
                }
                TextField("Quantity (e.g. 2 lbs)", text: $quantity)
                Toggle("Expiration date", isOn: $hasExpiration)
                if hasExpiration { DatePicker("Expires", selection: $expirationDate, displayedComponents: .date) }
            }
            .scrollContentBackground(.hidden).background(AppTheme.background)
            .navigationTitle("Add Pantry Item").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        modelContext.insert(PantryItem(name: name, category: category,
                                                       quantity: quantity, expirationDate: hasExpiration ? expirationDate : nil))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty).foregroundStyle(AppTheme.gold)
                }
            }
        }.presentationDetents([.medium])
    }
}

// MARK: - Scan Fridge Sheet
private struct ScanFridgeSheet: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannedItems: [ScannedIngredient] = []
    @State private var isScanning = false
    @State private var scanError: String?
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if scannedItems.isEmpty && !isScanning {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder").font(.system(size: 48)).foregroundStyle(AppTheme.gold)
                            Text("Select a fridge photo").foregroundStyle(AppTheme.textSecondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, 40).luxuryCard()
                    }
                } else if isScanning {
                    ProgressView("Scanning fridge...").foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(scannedItems) { item in
                            HStack {
                                let cat = IngredientCategory(rawValue: item.category) ?? .other
                                Image(systemName: cat.icon).foregroundStyle(AppTheme.gold).frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(item.name).foregroundStyle(AppTheme.textPrimary)
                                    Text("\(item.estimatedQuantity) \u{2022} \(item.category)")
                                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                    }.scrollContentBackground(.hidden)
                    Button("Add All to Pantry") { saveScannedItems() }.luxuryButton().padding(.horizontal)
                }
                if let err = scanError { Text(err).font(.caption).foregroundStyle(AppTheme.negative) }
            }
            .padding(.vertical).background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Scan Fridge").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                scanPhoto(newValue)
            }
        }
    }
    private func scanPhoto(_ item: PhotosPickerItem) {
        isScanning = true
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run { scanError = "Could not load image"; isScanning = false }; return
                }
                let result = try await FridgeInventoryService().scanFridge(image: image)
                await MainActor.run { scannedItems = result.items; isScanning = false }
            } catch {
                await MainActor.run { scanError = error.localizedDescription; isScanning = false }
            }
        }
    }
    private func saveScannedItems() {
        for s in scannedItems {
            let cat = IngredientCategory(rawValue: s.category) ?? .other
            let exp = s.estimatedDaysUntilExpiry.map { Date().addingTimeInterval(Double($0) * 86400) }
            modelContext.insert(PantryItem(name: s.name, category: cat, quantity: s.estimatedQuantity, expirationDate: exp))
        }
        dismiss()
    }
}

#Preview {
    PantryView()
        .modelContainer(for: [PantryItem.self, UserProfile.self, Meal.self], inMemory: true)
        .preferredColorScheme(.dark)
}
