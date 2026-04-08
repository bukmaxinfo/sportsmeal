import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    var icon: String {
        switch self {
        case .system: return "gear"
        case .english: return "e.circle.fill"
        case .chinese: return "character.textbox"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") var selectedLanguage: String = AppLanguage.system.rawValue

    var currentLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .system
    }

    var currentLanguageName: String {
        currentLanguage.displayName
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language.rawValue

        if language == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }

        // Force bundle to reload
        UserDefaults.standard.synchronize()
    }
}
