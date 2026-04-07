import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case running = "Running"
    case walking = "Walking"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case weightTraining = "Weight Training"
    case yoga = "Yoga"
    case hiit = "HIIT"
    case dancing = "Dancing"
    case hiking = "Hiking"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .weightTraining: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .hiit: return "bolt.heart.fill"
        case .dancing: return "figure.dance"
        case .hiking: return "figure.hiking"
        case .other: return "figure.mixed.cardio"
        }
    }

    // MET (Metabolic Equivalent of Task) values — average intensity
    var metValue: Double {
        switch self {
        case .running: return 9.8
        case .walking: return 3.8
        case .cycling: return 7.5
        case .swimming: return 7.0
        case .weightTraining: return 5.0
        case .yoga: return 3.0
        case .hiit: return 10.0
        case .dancing: return 5.5
        case .hiking: return 6.0
        case .other: return 5.0
        }
    }
}

@Model
final class ExerciseEntry {
    var type: ExerciseType
    var durationMinutes: Int
    var timestamp: Date

    init(type: ExerciseType = .running, durationMinutes: Int = 30, timestamp: Date = Date()) {
        self.type = type
        self.durationMinutes = durationMinutes
        self.timestamp = timestamp
    }

    // Calories burned = MET × weight(kg) × duration(hours)
    func caloriesBurned(weightKg: Double) -> Double {
        let hours = Double(durationMinutes) / 60.0
        return type.metValue * weightKg * hours
    }
}
