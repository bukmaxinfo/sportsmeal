import Foundation
import HealthKit

struct HealthWorkout: Identifiable {
    let id = UUID()
    let activityType: HKWorkoutActivityType
    let name: String
    let icon: String
    let durationMinutes: Int
    let caloriesBurned: Double
    let startDate: Date
    let source: String  // e.g., "Apple Watch", "Strava", "Nike Run Club"
}

class HealthKitService: ObservableObject {

    // MARK: - Published state

    @Published var isAuthorized: Bool = false
    @Published var latestWeight: Double?      // kg
    @Published var todaySteps: Int?
    @Published var todayActiveCalories: Double?
    @Published var todayWorkouts: [HealthWorkout] = []

    // MARK: - Private

    private let healthStore = HKHealthStore()

    private var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Types we read / write

    private var readTypes: Set<HKObjectType> {
        guard
            let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass),
            let steps = HKQuantityType.quantityType(forIdentifier: .stepCount),
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return [] }
        return [bodyMass, steps, activeEnergy, HKWorkoutType.workoutType()]
    }

    private var writeTypes: Set<HKSampleType> {
        guard
            let dietaryEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        else { return [] }
        var types: Set<HKSampleType> = [dietaryEnergy, HKWorkoutType.workoutType()]
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() {
        guard isAvailable else { return }

        let allRead = readTypes
        let allWrite = writeTypes

        healthStore.requestAuthorization(toShare: allWrite, read: allRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchLatestWeight()
                    self?.fetchTodaySteps()
                    self?.fetchTodayActiveCalories()
                    self?.fetchTodayWorkouts()
                } else {
                    self?.isAuthorized = false
                }
            }
        }
    }

    // MARK: - Fetch latest weight

    func fetchLatestWeight() {
        guard isAvailable,
              let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)
        else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            DispatchQueue.main.async {
                self?.latestWeight = kg
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Fetch today's steps

    func fetchTodaySteps() {
        guard isAvailable,
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        else { return }

        let predicate = predicateForToday()

        let query = HKStatisticsQuery(
            quantityType: stepsType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let steps = Int(sum.doubleValue(for: .count()))
            DispatchQueue.main.async {
                self?.todaySteps = steps
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Fetch today's active calories

    func fetchTodayActiveCalories() {
        guard isAvailable,
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        else { return }

        let predicate = predicateForToday()

        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let kcal = sum.doubleValue(for: .kilocalorie())
            DispatchQueue.main.async {
                self?.todayActiveCalories = kcal
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Fetch today's workouts from Apple Watch / Health

    func fetchTodayWorkouts() {
        guard isAvailable else { return }

        let predicate = predicateForToday()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: HKWorkoutType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else { return }

            let mapped = workouts.map { workout in
                HealthWorkout(
                    activityType: workout.workoutActivityType,
                    name: Self.workoutName(for: workout.workoutActivityType),
                    icon: Self.workoutIcon(for: workout.workoutActivityType),
                    durationMinutes: Int(workout.duration / 60),
                    caloriesBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    startDate: workout.startDate,
                    source: workout.sourceRevision.source.name
                )
            }

            DispatchQueue.main.async {
                self?.todayWorkouts = mapped
            }
        }
        healthStore.execute(query)
    }

    private static func workoutName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running:                       return "Running"
        case .walking:                       return "Walking"
        case .cycling:                       return "Cycling"
        case .swimming:                      return "Swimming"
        case .traditionalStrengthTraining:   return "Weight Training"
        case .yoga:                          return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        case .dance:                         return "Dancing"
        case .hiking:                        return "Hiking"
        case .elliptical:                    return "Elliptical"
        case .stairClimbing:                 return "Stairs"
        case .functionalStrengthTraining:    return "Strength"
        case .coreTraining:                  return "Core"
        case .flexibility:                   return "Stretching"
        case .mixedCardio:                   return "Cardio"
        default:                             return "Workout"
        }
    }

    private static func workoutIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running:                       return "figure.run"
        case .walking:                       return "figure.walk"
        case .cycling:                       return "bicycle"
        case .swimming:                      return "figure.pool.swim"
        case .traditionalStrengthTraining:   return "dumbbell.fill"
        case .yoga:                          return "figure.mind.and.body"
        case .highIntensityIntervalTraining: return "bolt.heart.fill"
        case .dance:                         return "figure.dance"
        case .hiking:                        return "figure.hiking"
        case .elliptical:                    return "figure.elliptical"
        case .stairClimbing:                 return "figure.stairs"
        default:                             return "figure.mixed.cardio"
        }
    }

    // MARK: - Save meal calories

    func saveMealCalories(calories: Double, date: Date) {
        guard isAvailable,
              let dietaryEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        else { return }

        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let sample = HKQuantitySample(
            type: dietaryEnergyType,
            quantity: quantity,
            start: date,
            end: date
        )

        healthStore.save(sample) { success, error in
            if let error = error {
                print("HealthKit: failed to save meal calories — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Save workout

    func saveWorkout(type exerciseType: ExerciseType, durationMinutes: Int, caloriesBurned: Double, date: Date) {
        guard isAvailable else { return }

        let duration = TimeInterval(durationMinutes * 60)
        let endDate = date.addingTimeInterval(duration)
        let energyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned)

        let workout = HKWorkout(
            activityType: hkActivityType(for: exerciseType),
            start: date,
            end: endDate,
            duration: duration,
            totalEnergyBurned: energyBurned,
            totalDistance: nil,
            metadata: nil
        )

        healthStore.save(workout) { success, error in
            if let error = error {
                print("HealthKit: failed to save workout — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    private func predicateForToday() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
    }

    private func hkActivityType(for exerciseType: ExerciseType) -> HKWorkoutActivityType {
        switch exerciseType {
        case .running:         return .running
        case .walking:         return .walking
        case .cycling:         return .cycling
        case .swimming:        return .swimming
        case .weightTraining:  return .traditionalStrengthTraining
        case .yoga:            return .yoga
        case .hiit:            return .highIntensityIntervalTraining
        case .dancing:         return .dance
        case .hiking:          return .hiking
        case .other:           return .mixedCardio
        }
    }
}
