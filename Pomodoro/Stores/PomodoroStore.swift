import Foundation
import Observation
import SwiftData

struct FocusBucket: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
}

struct HeatmapBucket: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

struct TagBreakdown: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let minutes: Double
}

struct PomodoroStats {
    let pomodorosToday: Int
    let minutesToday: Int
    let longestStreak: Int
    let dailyFocus: [FocusBucket]
    let trend: [FocusBucket]
    let heatmap: [HeatmapBucket]
    let tagBreakdown: [TagBreakdown]
}

@Observable
@MainActor
final class PomodoroStore {
    let container: ModelContainer
    let context: ModelContext
    private(set) var sessionVersion: Int = 0

    init(inMemory: Bool = false) {
        let schema = Schema([PomodoroSession.self, Tag.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
            ensureDefaultTags()
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    func ensureDefaultTags() {
        guard fetchTags().isEmpty else { return }
        Tag.presets.forEach { preset in
            context.insert(Tag(id: preset.id, name: preset.name, colorHex: preset.colorHex, focusDurationMinutes: preset.focusDurationMinutes, isDefault: preset.isDefault))
        }
        save()
    }

    /// Updates preset tag names to match the current locale, skipping tags the user has renamed.
    /// TODO Is this function really necessary? It only runs on app launch and the performance impact should be negligible, but it does add complexity. An alternative would be to simply not update preset names after creation, but that means users won't see localized names if they change their language or if we add new presets in the future.
    func syncPresetTagNames() {
        var changed = false
        for tag in fetchTags() {
            guard let key = Tag.presetLocalizationKeyByColor[tag.colorHex] else { continue }
            guard Tag.allKnownPresetNames.contains(tag.name) else { continue }
            let localized = String(localized: String.LocalizationValue(key))
            if tag.name != localized {
                tag.name = localized
                changed = true
            }
        }
        if changed { save() }
    }

    func fetchTags() -> [Tag] {
        let descriptor = FetchDescriptor<Tag>()
        let tags = (try? context.fetch(descriptor)) ?? []
        return tags.sorted {
            if $0.isDefault != $1.isDefault { return $0.isDefault }
            return $0.focusDurationMinutes < $1.focusDurationMinutes
        }
    }

    func fetchTag(id: UUID) -> Tag? {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { tag in
            tag.id == id
        })
        return try? context.fetch(descriptor).first
    }

    func fetchSessions() -> [PomodoroSession] {
        let descriptor = FetchDescriptor<PomodoroSession>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func createTag(name: String, colorHex: String, focusDurationMinutes: Int) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        context.insert(Tag(name: trimmedName, colorHex: colorHex, focusDurationMinutes: focusDurationMinutes))
        save()
    }

    func updateTag(_ tag: Tag, name: String, colorHex: String, focusDurationMinutes: Int) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        tag.name = trimmedName
        tag.colorHex = colorHex
        tag.focusDurationMinutes = focusDurationMinutes
        save()
    }

    func deleteTag(_ tag: Tag) {
        guard !tag.isDefault else { return }
        context.delete(tag)
        save()
    }

    func saveCompletedSession(startTime: Date, endTime: Date, phase: PomodoroPhase, tag: Tag?) {
        let duration = Int(endTime.timeIntervalSince(startTime))
        let session = PomodoroSession(
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            isCompleted: true,
            phase: phase,
            tag: tag
        )
        context.insert(session)
        sessionVersion += 1
        save()
    }

    func focusSessions() -> [PomodoroSession] {
        fetchSessions().filter { $0.isCompleted && $0.phase == .work }
    }

    func focusMinutesToday(referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        return focusSessions()
            .filter { calendar.isDate($0.startTime, inSameDayAs: referenceDate) }
            .reduce(0) { $0 + Int(Double($1.duration) / 60.0) }
    }

    func completedPomodorosToday(referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        return focusSessions().filter { calendar.isDate($0.startTime, inSameDayAs: referenceDate) }.count
    }

    func dailyFocus(last days: Int) -> [FocusBucket] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now)) ?? .now
        let grouped = Dictionary(grouping: focusSessions().filter { $0.startTime >= start }) {
            calendar.startOfDay(for: $0.startTime)
        }

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let sessions = grouped[date, default: []]
            let minutes = sessions.reduce(0.0) { $0 + Double($1.duration) / 60.0 }
            return FocusBucket(date: date, minutes: minutes)
        }
    }

    func heatmap(last days: Int) -> [HeatmapBucket] {
        dailyFocus(last: days).map { bucket in
            HeatmapBucket(date: bucket.date, minutes: Int(bucket.minutes.rounded()))
        }
    }

    func tagBreakdown() -> [TagBreakdown] {
        let grouped = Dictionary(grouping: focusSessions()) { $0.tag }
        return grouped.compactMap { tag, sessions in
            guard let tag else { return nil }
            let minutes = sessions.reduce(0.0) { $0 + Double($1.duration) / 60.0 }
            return TagBreakdown(id: tag.id, name: tag.name, colorHex: tag.colorHex, minutes: minutes)
        }
        .sorted { $0.minutes > $1.minutes }
    }

    func focusTrend(last days: Int) -> [FocusBucket] {
        dailyFocus(last: days)
    }

    func longestStreakDays(last days: Int) -> Int {
        let calendar = Calendar.current
        let activeDays = Set(focusSessions().map { calendar.startOfDay(for: $0.startTime) })
        let sortedDays = activeDays.sorted()
        var longest = 0
        var current = 0
        var previous: Date?

        for day in sortedDays {
            if let previous,
               let expected = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(day, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            previous = day
            longest = max(longest, current)
        }

        return longest
    }

    /// Computes all stats from a single `focusSessions()` fetch, avoiding 7 redundant queries.
    func loadStats(dailyDays: Int = 14, trendDays: Int = 30, heatmapDays: Int = 70, referenceDate: Date = .now) -> PomodoroStats {
        let sessions = focusSessions()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        // Today's totals
        let todaySessions = sessions.filter { calendar.startOfDay(for: $0.startTime) == today }
        let pomodorosToday = todaySessions.count
        let minutesToday = todaySessions.reduce(0) { $0 + $1.duration } / 60

        // Longest streak (all sessions)
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startTime) }).sorted()
        var longest = 0, current = 0, previous: Date?
        for day in activeDays {
            if let prev = previous,
               calendar.date(byAdding: .day, value: 1, to: prev) == day {
                current += 1
            } else {
                current = 1
            }
            previous = day
            longest = max(longest, current)
        }

        // Bucket sessions by day (one pass, covers all three ranges)
        let maxDays = max(dailyDays, max(trendDays, heatmapDays))
        let overallStart = calendar.date(byAdding: .day, value: -(maxDays - 1), to: today) ?? today
        let grouped = Dictionary(
            grouping: sessions.filter { $0.startTime >= overallStart },
            by: { calendar.startOfDay(for: $0.startTime) }
        )

        func makeBuckets(days: Int) -> [FocusBucket] {
            let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
            return (0..<days).compactMap { offset in
                guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
                let minutes = Double(grouped[date, default: []].reduce(0) { $0 + $1.duration }) / 60.0
                return FocusBucket(date: date, minutes: minutes)
            }
        }

        let daily = makeBuckets(days: dailyDays)
        let trend = makeBuckets(days: trendDays)
        let heatmapBuckets = makeBuckets(days: heatmapDays).map {
            HeatmapBucket(date: $0.date, minutes: Int($0.minutes.rounded()))
        }

        // Tag breakdown
        let tagGrouped = Dictionary(grouping: sessions, by: { $0.tag })
        let tags: [TagBreakdown] = tagGrouped.compactMap { tag, s in
            guard let tag else { return nil }
            let minutes = Double(s.reduce(0) { $0 + $1.duration }) / 60.0
            return TagBreakdown(id: tag.id, name: tag.name, colorHex: tag.colorHex, minutes: minutes)
        }.sorted { $0.minutes > $1.minutes }

        return PomodoroStats(
            pomodorosToday: pomodorosToday,
            minutesToday: minutesToday,
            longestStreak: longest,
            dailyFocus: daily,
            trend: trend,
            heatmap: heatmapBuckets,
            tagBreakdown: tags
        )
    }

    private func save() {
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("[PomodoroStore] Save failed: \(error)")
            #endif
        }
    }
}
