import Foundation
import Observation

@Observable
@MainActor
final class AppSettings {
    var shortBreakMinutes: Int {
        didSet { defaults.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes) }
    }
    var longBreakMinutes: Int {
        didSet { defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes) }
    }
    var longBreakInterval: Int {
        didSet { defaults.set(longBreakInterval, forKey: Keys.longBreakInterval) }
    }
    var autoStartNextPhase: Bool {
        didSet { defaults.set(autoStartNextPhase, forKey: Keys.autoStartNextPhase) }
    }
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    var floatingPanelVisible: Bool {
        didSet { defaults.set(floatingPanelVisible, forKey: Keys.floatingPanelVisible) }
    }
    var focusDurationMinutes: Int {
        didSet { defaults.set(focusDurationMinutes, forKey: Keys.focusDurationMinutes) }
    }
    var selectedTagID: UUID? {
        didSet {
            if let selectedTagID {
                defaults.set(selectedTagID.uuidString, forKey: Keys.selectedTagID)
            } else {
                defaults.removeObject(forKey: Keys.selectedTagID)
            }
        }
    }
    /// Language override: "" = follow system, "en", "zh-Hans", "zh-Hant", "ja"
    var appLanguage: String {
        didSet {
            defaults.set(appLanguage, forKey: Keys.appLanguage)
            AppSettings.applyLanguage(appLanguage)
        }
    }

    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let defaults = UserDefaults.standard
        shortBreakMinutes = defaults.integer(forKey: Keys.shortBreakMinutes).nonZero(or: 5)
        longBreakMinutes = defaults.integer(forKey: Keys.longBreakMinutes).nonZero(or: 15)
        longBreakInterval = defaults.integer(forKey: Keys.longBreakInterval).nonZero(or: 4)
        autoStartNextPhase = defaults.object(forKey: Keys.autoStartNextPhase) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        floatingPanelVisible = defaults.object(forKey: Keys.floatingPanelVisible) as? Bool ?? false
        focusDurationMinutes = defaults.integer(forKey: Keys.focusDurationMinutes).nonZero(or: 25)
        selectedTagID = defaults.string(forKey: Keys.selectedTagID).flatMap(UUID.init(uuidString:))
        appLanguage = defaults.string(forKey: Keys.appLanguage) ?? ""
    }

    /// Call at app startup (before any views render) to restore the saved language override.
    static func applyLanguagePreference() {
        let lang = UserDefaults.standard.string(forKey: Keys.appLanguage) ?? ""
        applyLanguage(lang)
    }

    private static func applyLanguage(_ lang: String) {
        if lang.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        }
    }
}

private enum Keys {
    static let shortBreakMinutes = "settings.shortBreakMinutes"
    static let longBreakMinutes = "settings.longBreakMinutes"
    static let longBreakInterval = "settings.longBreakInterval"
    static let autoStartNextPhase = "settings.autoStartNextPhase"
    static let notificationsEnabled = "settings.notificationsEnabled"
    static let soundEnabled = "settings.soundEnabled"
    static let floatingPanelVisible = "settings.floatingPanelVisible"
    static let focusDurationMinutes = "settings.focusDurationMinutes"
    static let selectedTagID = "settings.selectedTagID"
    static let appLanguage = "settings.appLanguage"
}

private extension Int {
    func nonZero(or fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}
