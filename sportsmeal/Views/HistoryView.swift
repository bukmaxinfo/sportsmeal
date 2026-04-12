import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @Query private var profiles: [UserProfile]
    @State private var selectedTab = 0
    @State private var showingExportSheet = false

    private var dailyBudget: Double { profiles.first?.bmr ?? 2000 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("List").tag(0)
                    Text("Charts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    mealListView
                } else {
                    chartView
                }
            }
            .background(AppTheme.background)
            .navigationTitle("History")
            .toolbar {
                if !meals.isEmpty {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                let csv = DataExportService.exportMealsAsCSV(meals: meals)
                if let data = csv.data(using: .utf8) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sportsmeal_history.csv")
                    let _ = try? data.write(to: tempURL)
                    ShareSheet(items: [tempURL])
                }
            }
        }
    }

    private var mealListView: some View {
        Group {
            if meals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("No Meals Yet")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Your meal history will appear here")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedMeals, id: \.0) { date, dayMeals in
                        Section {
                            ForEach(dayMeals) { meal in
                                NavigationLink {
                                    MealDetailView(meal: meal)
                                } label: {
                                    MealRowView(meal: meal)
                                }
                                .listRowBackground(AppTheme.surface)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation { modelContext.delete(meal) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            let total = dayMeals.reduce(0) { $0 + $1.totalCalories }
                            let isOver = total > dailyBudget
                            HStack {
                                Text(date, style: .date)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text("\(Int(total)) / \(Int(dailyBudget)) kcal")
                                    .font(.caption.bold())
                                    .foregroundStyle(isOver ? AppTheme.negative : AppTheme.gold)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var chartView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Calories")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Chart {
                        ForEach(last7DaysData, id: \.date) { entry in
                            BarMark(
                                x: .value("Day", entry.date, unit: .day),
                                y: .value("Calories", entry.calories)
                            )
                            .foregroundStyle(entry.calories > dailyBudget ? AnyShapeStyle(AppTheme.negative.opacity(0.8)) : AnyShapeStyle(AppTheme.goldGradient))
                            .cornerRadius(4)
                        }
                        RuleMark(y: .value("Budget", dailyBudget))
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Budget")
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                    }
                    .accessibilityLabel("Daily calories over the last 7 days")
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(AppTheme.border)
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .frame(height: 200)
                }
                .luxuryCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Meals Per Day")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Chart(last7DaysData, id: \.date) { entry in
                        BarMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("Meals", entry.mealCount)
                        )
                        .foregroundStyle(AppTheme.positive)
                        .cornerRadius(4)
                    }
                    .accessibilityLabel("Meals per day over the last 7 days")
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(AppTheme.border)
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .frame(height: 150)
                }
                .luxuryCard()
            }
            .padding()
        }
    }

    private var groupedMeals: [(Date, [Meal])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private struct DailyData {
        let date: Date
        let calories: Double
        let mealCount: Int
    }

    private var last7DaysData: [DailyData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            let dayMeals = meals.filter { $0.timestamp >= date && $0.timestamp < nextDate }
            return DailyData(date: date, calories: dayMeals.reduce(0) { $0 + $1.totalCalories }, mealCount: dayMeals.count)
        }
        .reversed()
    }
}

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveTemplate = false
    @State private var templateName = ""
    @State private var templateSaved = false
    @State private var editingItemIndex: Int?
    @State private var editCalText = ""
    @State private var isEditing = false
    @State private var showingAddItem = false
    @State private var newItemName = ""
    @State private var newItemCalories = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let photoData = meal.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                }

                VStack(spacing: 8) {
                    Text("\(Int(meal.totalCalories))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.gold)
                    Text("Total Calories")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)

                    if meal.hasMacros {
                        HStack(spacing: 16) {
                            MacroPill(label: "Protein", value: meal.totalProtein, color: AppTheme.positive)
                            MacroPill(label: "Carbs", value: meal.totalCarbs, color: AppTheme.gold)
                            MacroPill(label: "Fat", value: meal.totalFat, color: AppTheme.warning)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Food Items")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        if isEditing {
                            Text("Tap calories to edit")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }

                    ForEach(Array(meal.foodItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 4) {
                            HStack {
                                if isEditing && meal.foodItems.count > 1 {
                                    Button {
                                        removeItem(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.negative.opacity(0.7))
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(item.portionSize)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                Spacer()
                                if isEditing && editingItemIndex == index {
                                    HStack(spacing: 4) {
                                        TextField("kcal", text: $editCalText)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 60)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(AppTheme.surfaceLight)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        Button {
                                            applyEdit(index: index)
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AppTheme.positive)
                                        }
                                    }
                                } else if isEditing {
                                    Button {
                                        editingItemIndex = index
                                        editCalText = "\(Int(item.calories))"
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("\(Int(item.calories)) kcal")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(AppTheme.gold)
                                            Image(systemName: "pencil")
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.textTertiary)
                                        }
                                    }
                                } else {
                                    Text("\(Int(item.calories)) kcal")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppTheme.gold)
                                }
                            }
                            if let p = item.proteinGrams, let c = item.carbsGrams, let f = item.fatGrams {
                                HStack(spacing: 12) {
                                    MacroPill(label: "P", value: p, color: AppTheme.positive)
                                    MacroPill(label: "C", value: c, color: AppTheme.gold)
                                    MacroPill(label: "F", value: f, color: AppTheme.warning)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 2)
                        Divider().overlay(AppTheme.border)
                    }

                    // Add item in edit mode
                    if isEditing {
                        if showingAddItem {
                            VStack(spacing: 8) {
                                TextField("Food name", text: $newItemName)
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(AppTheme.surfaceLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                HStack {
                                    TextField("Calories", text: $newItemCalories)
                                        .keyboardType(.numberPad)
                                        .font(.subheadline)
                                        .padding(8)
                                        .background(AppTheme.surfaceLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Button { addItem() } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.positive)
                                            .font(.title3)
                                    }
                                    .disabled(newItemName.isEmpty || newItemCalories.isEmpty)
                                    Button {
                                        showingAddItem = false
                                        newItemName = ""
                                        newItemCalories = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppTheme.textTertiary)
                                            .font(.title3)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        } else {
                            Button { showingAddItem = true } label: {
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
                }
                .luxuryCard()

                (Text(meal.timestamp, style: .date) + Text(" at ") + Text(meal.timestamp, style: .time))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Meal Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        isEditing.toggle()
                        editingItemIndex = nil
                    } label: {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .foregroundStyle(AppTheme.gold)
                    }
                    Button {
                        templateName = meal.foodItems.map(\.name).joined(separator: " + ")
                        showingSaveTemplate = true
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppTheme.negative)
                }
            }
        }
        .alert("Save as Template", isPresented: $showingSaveTemplate) {
            TextField("Template name", text: $templateName)
            Button("Save") {
                let template = MealTemplate(
                    name: templateName,
                    foodItems: meal.foodItems,
                    totalCalories: meal.totalCalories,
                    totalProtein: meal.totalProtein,
                    totalCarbs: meal.totalCarbs,
                    totalFat: meal.totalFat
                )
                modelContext.insert(template)
                templateSaved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { templateSaved = false }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this meal as a quick-log template.")
        }
        .overlay(alignment: .top) {
            if templateSaved {
                Label("Template saved!", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.positive)
                    .padding(10)
                    .background(AppTheme.surface)
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut, value: templateSaved)
        .confirmationDialog("Delete this meal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(meal)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this meal and its \(Int(meal.totalCalories)) kcal from your history.")
        }
    }

    private func applyEdit(index: Int) {
        guard let newCal = Double(editCalText), index < meal.foodItems.count else { return }
        var items = meal.foodItems
        items[index] = FoodItem(
            name: items[index].name,
            calories: newCal,
            portionSize: items[index].portionSize,
            proteinGrams: items[index].proteinGrams,
            carbsGrams: items[index].carbsGrams,
            fatGrams: items[index].fatGrams
        )
        meal.foodItems = items
        meal.totalCalories = items.reduce(0) { $0 + $1.calories }
        editingItemIndex = nil
    }

    private func removeItem(at index: Int) {
        guard index < meal.foodItems.count else { return }
        var items = meal.foodItems
        items.remove(at: index)
        meal.foodItems = items
        meal.totalCalories = items.reduce(0) { $0 + $1.calories }
        if editingItemIndex == index { editingItemIndex = nil }
    }

    private func addItem() {
        guard !newItemName.isEmpty, let cal = Double(newItemCalories) else { return }
        var items = meal.foodItems
        items.append(FoodItem(name: newItemName, calories: cal))
        meal.foodItems = items
        meal.totalCalories = items.reduce(0) { $0 + $1.calories }
        newItemName = ""
        newItemCalories = ""
        showingAddItem = false
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HistoryView()
        .modelContainer(for: Meal.self, inMemory: true)
        .preferredColorScheme(.dark)
}
