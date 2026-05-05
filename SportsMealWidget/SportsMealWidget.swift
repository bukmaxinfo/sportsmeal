import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry
struct CalorieEntry: TimelineEntry {
    let date: Date
    let consumed: Double
    let budget: Double
    let mealCount: Int
    let recentMeals: [String]
    let protein: Double
    let carbs: Double
    let fat: Double

    var remaining: Double { max(0, budget - consumed) }
    var progress: Double { budget > 0 ? min(consumed / budget, 1.0) : 0 }
    var isOver: Bool { consumed > budget }

    static let placeholder = CalorieEntry(
        date: Date(),
        consumed: 1247,
        budget: 2000,
        mealCount: 3,
        recentMeals: ["Oatmeal", "Chicken Salad", "Pasta"],
        protein: 65,
        carbs: 140,
        fat: 42
    )
}

// MARK: - Shared App Group reader
private enum SharedDefaults {
    static let suiteName = "group.com.bukmax.sportsmeal"

    private enum Key {
        static let consumed = "widget_consumedCalories"
        static let budget = "widget_calorieBudget"
        static let mealCount = "widget_mealCount"
        static let recentMeals = "widget_recentMeals"
        static let protein = "widget_protein"
        static let carbs = "widget_carbs"
        static let fat = "widget_fat"
        static let lastUpdated = "widget_lastUpdated"
    }

    static func readEntry() -> CalorieEntry {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return .placeholder
        }

        let lastUpdated = Date(timeIntervalSince1970: defaults.double(forKey: Key.lastUpdated))
        let isFromToday = Calendar.current.isDateInToday(lastUpdated)

        // If data is stale (not from today), show zeroed-out state
        guard isFromToday else {
            return CalorieEntry(
                date: Date(),
                consumed: 0,
                budget: defaults.double(forKey: Key.budget).nonZero ?? 2000,
                mealCount: 0,
                recentMeals: [],
                protein: 0,
                carbs: 0,
                fat: 0
            )
        }

        return CalorieEntry(
            date: Date(),
            consumed: defaults.double(forKey: Key.consumed),
            budget: defaults.double(forKey: Key.budget).nonZero ?? 2000,
            mealCount: defaults.integer(forKey: Key.mealCount),
            recentMeals: defaults.stringArray(forKey: Key.recentMeals) ?? [],
            protein: defaults.double(forKey: Key.protein),
            carbs: defaults.double(forKey: Key.carbs),
            fat: defaults.double(forKey: Key.fat)
        )
    }
}

private extension Double {
    /// Returns nil if zero, so callers can use `??` for default values.
    var nonZero: Double? { self == 0 ? nil : self }
}

// MARK: - Timeline Provider
struct CalorieTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(SharedDefaults.readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = SharedDefaults.readEntry()
        // Refresh at midnight (new day resets) or in 30 min, whichever is sooner.
        // The main app also triggers immediate reloads via WidgetCenter on every meal change.
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        let thirtyMin = Date().addingTimeInterval(30 * 60)
        let nextUpdate = min(midnight, thirtyMin)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Colors
enum WidgetTheme {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let gold = Color(red: 0.85, green: 0.72, blue: 0.45)
    static let goldLight = Color(red: 0.92, green: 0.82, blue: 0.58)
    static let positive = Color(red: 0.40, green: 0.78, blue: 0.58)
    static let negative = Color(red: 0.85, green: 0.35, blue: 0.35)
    static let warning = Color(red: 0.90, green: 0.70, blue: 0.30)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.30)
    static let ringBg = Color.white.opacity(0.08)

    static let goldGradient = LinearGradient(
        colors: [gold, goldLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Small Widget
struct SmallCalorieView: View {
    let entry: CalorieEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(WidgetTheme.ringBg, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.isOver ? WidgetTheme.negative : WidgetTheme.gold,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(entry.remaining))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.textPrimary)
                    Text("kcal left")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetTheme.textTertiary)
                }
            }
            .frame(width: 80, height: 80)

            Text("\(entry.mealCount) meals today")
                .font(.system(size: 10))
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WidgetTheme.background, for: .widget)
    }
}

// MARK: - Medium Widget
struct MediumCalorieView: View {
    let entry: CalorieEntry

    var body: some View {
        HStack(spacing: 16) {
            // Calorie ring
            ZStack {
                Circle()
                    .stroke(WidgetTheme.ringBg, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.isOver ? WidgetTheme.negative : WidgetTheme.gold,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(entry.remaining))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.textPrimary)
                    Text("kcal left")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetTheme.textTertiary)
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text("Today's Meals")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.gold)

                if entry.recentMeals.isEmpty {
                    Text("No meals logged")
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetTheme.textTertiary)
                } else {
                    ForEach(entry.recentMeals.prefix(3), id: \.self) { meal in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(WidgetTheme.gold)
                                .frame(width: 4, height: 4)
                            Text(meal)
                                .font(.system(size: 11))
                                .foregroundStyle(WidgetTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Macro summary
                HStack(spacing: 8) {
                    macroLabel("P", value: entry.protein, color: WidgetTheme.positive)
                    macroLabel("C", value: entry.carbs, color: WidgetTheme.gold)
                    macroLabel("F", value: entry.fat, color: WidgetTheme.warning)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WidgetTheme.background, for: .widget)
    }

    private func macroLabel(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.system(size: 9))
                .foregroundStyle(WidgetTheme.textTertiary)
        }
    }
}

// MARK: - Lock Screen Widget
struct LockScreenCalorieView: View {
    let entry: CalorieEntry

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(entry.remaining))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("kcal")
                .font(.system(size: 9))
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Widget Definitions
struct SportsMealSmallWidget: Widget {
    let kind: String = "SportsMealCalorieRing"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieTimelineProvider()) { entry in
            SmallCalorieView(entry: entry)
        }
        .configurationDisplayName("Calorie Ring")
        .description("Track your remaining calories at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct SportsMealMediumWidget: Widget {
    let kind: String = "SportsMealDailyOverview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieTimelineProvider()) { entry in
            MediumCalorieView(entry: entry)
        }
        .configurationDisplayName("Daily Overview")
        .description("Calorie ring with today's meals and macros.")
        .supportedFamilies([.systemMedium])
    }
}

struct SportsMealLockScreenWidget: Widget {
    let kind: String = "SportsMealLockScreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieTimelineProvider()) { entry in
            LockScreenCalorieView(entry: entry)
        }
        .configurationDisplayName("Calories Remaining")
        .description("Simple calorie count for your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Widget Bundle
@main
struct SportsMealWidgetBundle: WidgetBundle {
    var body: some Widget {
        SportsMealSmallWidget()
        SportsMealMediumWidget()
        SportsMealLockScreenWidget()
    }
}
