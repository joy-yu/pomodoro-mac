# Features

## Implemented

- Menu bar app (`MenuBarExtra`); label shows remaining time + phase icon
- Timer: start, pause, resume, reset, skip; work / short break / long break phases
- Configurable durations and long-break interval
- Auto-start next phase option
- Sound-enabled option (wired to `UNNotificationPresentationOptions`)
- SwiftData persistence for tags and completed focus sessions
- Floating `NSPanel` timer with drag-to-reposition
- Menu bar UI with four tabs: Focus / Stats / Tags / Settings
- Stats dashboard: bar chart (14 d), trend line (30 d), heatmap (70 d), tag donut + legend
- Tag management: create, edit, delete; color picker; default presets on first launch
- Phase-aware color system: progress arc and cycle indicator change color per phase
- Centralized animation constants (`AppTheme.Animation`)

## Not Yet Implemented

- Global keyboard shortcuts (start/pause, show/hide floating panel)
- Notification action buttons ("Start Break", "Skip Break")
- Custom sound assets; richer audio playback
- Day / week / month filter for statistics
- Persistent floating panel position (save/restore `frame.origin`)
- Unit tests for timer phase transitions and store aggregation

## Good Next Tasks

- Global shortcuts via `CGKeyCode` or `MASShortcut`-equivalent
- `UNNotificationAction` for break/skip actions in notification banners
- StatsView date range picker (day / week / month segmentation)
- Save panel origin to UserDefaults on drag end; restore in `show()`
- Unit tests: `TimerEngine` phase transitions, `PomodoroStore` aggregation
