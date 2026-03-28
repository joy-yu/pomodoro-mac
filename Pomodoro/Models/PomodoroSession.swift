import Foundation
import SwiftData

@Model
final class PomodoroSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: Int
    var isCompleted: Bool
    var phaseRawValue: String
    var tag: Tag?

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        duration: Int,
        isCompleted: Bool,
        phase: PomodoroPhase,
        tag: Tag? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.isCompleted = isCompleted
        self.phaseRawValue = phase.rawValue
        self.tag = tag
    }

    var phase: PomodoroPhase {
        get { PomodoroPhase(rawValue: phaseRawValue) ?? .work }
        set { phaseRawValue = newValue.rawValue }
    }
}
