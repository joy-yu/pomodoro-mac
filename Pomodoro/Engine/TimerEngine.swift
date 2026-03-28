import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class TimerEngine {
    var state: TimerState = .idle
    var currentPhase: PomodoroPhase = .work
    var remainingSeconds: Int
    var completedPomodoros: Int = 0
    var selectedTag: Tag?

    private let settings: AppSettings
    private let store: PomodoroStore
    private let notifications: NotificationManager
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var sleepDate: Date?

    init(settings: AppSettings, store: PomodoroStore, notifications: NotificationManager) {
        self.settings = settings
        self.store = store
        self.notifications = notifications
        remainingSeconds = 25 * 60
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemSleep()
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemWake()
            }
        }
    }

    var totalDuration: Int {
        duration(for: currentPhase)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (Double(remainingSeconds) / Double(totalDuration))
    }

    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var currentPhaseDisplayTitle: String {
        if currentPhase == .work, let selectedTag {
            return selectedTag.name
        }
        return currentPhase.title
    }

    var effectiveFocusTitle: String {
        selectedTag?.name ?? String(localized: "phase.focus")
    }

    var effectiveFocusDurationMinutes: Int {
        selectedTag?.focusDurationMinutes ?? 25
    }

    var cycleStageCount: Int {
        max(settings.longBreakInterval, 1)
    }

    /// Number of filled badge slots to show in the timer face (0 … cycleStageCount).
    /// Uses phase-aware arithmetic so the display resets correctly at the start of each new cycle.
    var filledBadgesInCycle: Int {
        cycleStageIndex - (currentPhase == .work ? 1 : 0)
    }

    var cycleStageIndex: Int {
        let interval = cycleStageCount

        switch currentPhase {
        case .work:
            return min((completedPomodoros % interval) + 1, interval)
        case .shortBreak, .longBreak:
            let completedInCycle = completedPomodoros % interval
            return completedInCycle == 0 ? interval : completedInCycle
        }
    }

    var menuBarTitle: String {
        state == .running ? formattedRemainingTime : currentPhaseDisplayTitle
    }

    func toggle() {
        switch state {
        case .idle:
            startCurrentPhase()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func startCurrentPhase() {
        state = .running
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        state = .paused
    }

    func resume() {
        state = .running
        startTimer()
    }

    func reset() {
        timer?.invalidate()
        state = .idle
        remainingSeconds = duration(for: currentPhase)
    }

    func skipToNextPhase() {
        timer?.invalidate()
        completeCurrentPhase(triggeredBySkip: true)
    }

    func applySettings() {
        if state == .idle {
            remainingSeconds = duration(for: currentPhase)
        }
    }

    func selectTag(_ tag: Tag?) {
        selectedTag = tag
        settings.selectedTagID = tag?.id
        applySettings()
    }

    func restoreSelectedTag() {
        let tagID = settings.selectedTagID ?? Tag.defaultID
        if let tag = store.fetchTag(id: tagID) {
            selectedTag = tag
            applySettings()
        } else if let defaultTag = store.fetchTag(id: Tag.defaultID) {
            selectTag(defaultTag)
        }
        completedPomodoros = store.focusSessions().count
    }

    private func handleSystemSleep() {
        guard state == .running else { return }
        sleepDate = Date.now
        timer?.invalidate()
    }

    private func handleSystemWake() {
        guard state == .running, let slept = sleepDate else {
            sleepDate = nil
            return
        }
        sleepDate = nil
        let elapsed = Int(Date.now.timeIntervalSince(slept))
        remainingSeconds = max(remainingSeconds - elapsed, 0)
        if remainingSeconds == 0 {
            completeCurrentPhase(triggeredBySkip: false)
        } else {
            state = .paused
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            completeCurrentPhase(triggeredBySkip: false)
            return
        }
        remainingSeconds -= 1
    }

    private func completeCurrentPhase(triggeredBySkip: Bool) {
        timer?.invalidate()
        let finishedPhase = currentPhase

        if finishedPhase == .work, !triggeredBySkip {
            let endTime = Date.now
            let startTime = endTime.addingTimeInterval(-Double(duration(for: finishedPhase)))
            store.saveCompletedSession(startTime: startTime, endTime: endTime, phase: .work, tag: selectedTag)
            completedPomodoros += 1
        }

        currentPhase = nextPhase(after: finishedPhase)
        remainingSeconds = duration(for: currentPhase)
        state = .idle
        if settings.notificationsEnabled {
            notifications.sendPhaseFinishedNotification(for: finishedPhase, nextPhase: currentPhase, playSound: settings.soundEnabled)
        }

        if settings.autoStartNextPhase {
            startCurrentPhase()
        }
    }

    private func nextPhase(after phase: PomodoroPhase) -> PomodoroPhase {
        switch phase {
        case .work:
            return completedPomodoros > 0 && completedPomodoros.isMultiple(of: settings.longBreakInterval) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    private func duration(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .work:
            return (selectedTag?.focusDurationMinutes ?? 25) * 60
        case .shortBreak:
            return settings.shortBreakMinutes * 60
        case .longBreak:
            return settings.longBreakMinutes * 60
        }
    }

    deinit {
        timer?.invalidate()
    }
}
