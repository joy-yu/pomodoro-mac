import Foundation

enum PomodoroPhase: String, Codable, CaseIterable, Identifiable {
    case work
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:
            return String(localized: "phase.focus")
        case .shortBreak:
            return String(localized: "phase.shortBreak")
        case .longBreak:
            return String(localized: "phase.longBreak")
        }
    }

    var symbolName: String {
        switch self {
        case .work:
            return "flame.fill"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "leaf.fill"
        }
    }
    
    var notificationTitle: String {
        switch self {
        case .work:
            return String(localized: "notification.focusEnded")
        case .shortBreak, .longBreak:
            return String(localized: "notification.breakEnded")
        }
    }
}

enum TimerState: String {
    case idle
    case running
    case paused
}
