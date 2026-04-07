import SwiftUI

struct WatchHomeView: View {
    @State private var consumed: Double = 0
    @State private var budget: Double = 2000
    @State private var templates: [WatchMealTemplate] = []
    @State private var exerciseActive = false
    @State private var exerciseType: String = "Running"
    @State private var exerciseStartTime: Date?

    private var remaining: Double { max(0, budget - consumed) }
    private var progress: Double { budget > 0 ? min(consumed / budget, 1.0) : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Calorie Ring
                    calorieRing

                    // Quick Log
                    if !templates.isEmpty {
                        quickLogSection
                    }

                    // Exercise
                    exerciseSection
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("SportsMeal")
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Calorie Ring
    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    consumed > budget
                        ? Color.red
                        : Color(red: 0.85, green: 0.72, blue: 0.45),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(Int(remaining))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("kcal left")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(height: 110)
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Log
    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Log")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.45))

            ForEach(templates) { template in
                Button {
                    logMeal(template)
                } label: {
                    HStack {
                        Text(template.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("\(Int(template.calories))")
                            .font(.caption.bold())
                            .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.45))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Exercise
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(red: 0.40, green: 0.78, blue: 0.58))

            if exerciseActive, let start = exerciseStartTime {
                VStack(spacing: 6) {
                    Text(exerciseType)
                        .font(.caption.bold())
                    Text(start, style: .timer)
                        .font(.system(size: 20, design: .rounded))
                        .foregroundStyle(Color(red: 0.40, green: 0.78, blue: 0.58))

                    Button("Stop") {
                        stopExercise()
                    }
                    .tint(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                HStack(spacing: 6) {
                    exerciseButton("Run", icon: "figure.run")
                    exerciseButton("Walk", icon: "figure.walk")
                    exerciseButton("Cycle", icon: "figure.outdoor.cycle")
                }
            }
        }
    }

    private func exerciseButton(_ name: String, icon: String) -> some View {
        Button {
            startExercise(name)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(name)
                    .font(.system(size: 9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions
    private func loadData() {
        // In production, load via WatchConnectivity from iPhone app
        // Placeholder data for now
        templates = [
            WatchMealTemplate(name: "Oatmeal & Fruit", calories: 350),
            WatchMealTemplate(name: "Chicken Salad", calories: 420),
        ]
    }

    private func logMeal(_ template: WatchMealTemplate) {
        consumed += template.calories
        // In production, send via WatchConnectivity to iPhone
    }

    private func startExercise(_ type: String) {
        exerciseType = type
        exerciseStartTime = Date()
        exerciseActive = true
    }

    private func stopExercise() {
        exerciseActive = false
        exerciseStartTime = nil
        // In production, send exercise session via WatchConnectivity
    }
}

// MARK: - Watch Models
struct WatchMealTemplate: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
}
