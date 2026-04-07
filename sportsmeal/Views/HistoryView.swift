import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @State private var selectedTab = 0
    @State private var showingExportSheet = false

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
                            HStack {
                                Text(date, style: .date)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                let total = dayMeals.reduce(0) { $0 + $1.totalCalories }
                                Text("\(Int(total)) kcal")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.gold)
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

                    Chart(last7DaysData, id: \.date) { entry in
                        BarMark(
                            x: .value("Day", entry.date, unit: .day),
                            y: .value("Calories", entry.calories)
                        )
                        .foregroundStyle(AppTheme.goldGradient)
                        .cornerRadius(4)
                    }
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
                    Text("Food Items")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(meal.foodItems) { item in
                        VStack(spacing: 4) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(item.portionSize)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                Spacer()
                                Text("\(Int(item.calories)) kcal")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.gold)
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
                Button {
                    templateName = meal.foodItems.map(\.name).joined(separator: " + ")
                    showingSaveTemplate = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(AppTheme.gold)
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
