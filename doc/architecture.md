# Architecture

## Dependency Graph

All dependencies are created in `PomodoroApp.init()` and passed down explicitly — no singletons, no environment injection.

```
PomodoroApp
├── PomodoroStore              (ModelContainer, stats queries)
├── AppSettings                (@Observable, UserDefaults-backed)
├── NotificationManager        (UNUserNotificationCenter delegate)
├── TimerEngine(settings:store:notifications:)
└── FloatingPanelManager
      └── .configure(engine:settings:)   ← call before updateVisibility
          └── FloatingPanelView(engine:settings:onHide:onPanelDrag:onPanelDragEnd:)
              └── TimerFaceView(engine:)

MenuBarView(engine:settings:store:floatingPanelManager:)
└── FocusView(engine:)
    └── TimerFaceView(engine:)
```

## Timer Tick Flow

```
Timer.scheduledTimer (1 s) → TimerEngine.tick()
  → remainingSeconds -= 1
  → @Observable re-renders: TimerFaceView, MenuBarExtra label, FloatingPanel
  → remainingSeconds == 0 → completeCurrentPhase()
      → store.saveSession(...)           // work phases only
      → notifications.sendPhaseFinishedNotification(playSound: settings.soundEnabled)
      → advance phase, reset timer
      → auto-start if settings.autoStartNextPhase
```

## Floating Panel Visibility Flow

```
settings.floatingPanelVisible changes
  → MenuBarView.onChange → floatingPanelManager.updateVisibility(isVisible:)
      show(): create NSPanel + NSHostingController once; subsequent calls → makeKeyAndOrderFront
      hide(): panel.orderOut(nil)

App launch: PomodoroApp.init()
  → floatingPanelManager.configure(engine:settings:)
  → DispatchQueue.main.async { floatingPanelManager.updateVisibility(...) }
```

## Floating Panel Drag

`isMovableByWindowBackground` does not work because `NSHostingView` intercepts all mouse events.

**Implemented approach** (do not change):
- `FloatingPanelView` uses `.highPriorityGesture(DragGesture(minimumDistance: 4))`
- `.onChanged` calls `onPanelDrag()` → `FloatingPanelManager` reads `NSEvent.mouseLocation`
- `NSEvent.mouseLocation` is absolute screen coordinates (AppKit bottom-left origin), independent of window position — avoids the jitter from SwiftUI's window-relative translation feedback loop
- `dragBaseOrigin` + `dragBaseMouseLocation` captured once at drag start; delta applied each frame; cleared on drag end

## File Responsibilities

| File | Responsibility |
|---|---|
| `PomodoroApp.swift` | @main entry; owns and assembles all dependencies |
| `FloatingPanelManager.swift` | NSPanel lifecycle, initial positioning, drag math |
| `Engine/TimerEngine.swift` | @MainActor @Observable state machine; owns the Timer |
| `Engine/NotificationManager.swift` | UNUserNotificationCenter; foreground presentation + sound control |
| `Engine/AppSettings.swift` | @Observable user preferences, persisted to UserDefaults |
| `Models/PomodoroPhase.swift` | enum: .work / .shortBreak / .longBreak |
| `Models/PomodoroSession.swift` | @Model: persisted completed focus session |
| `Models/Tag.swift` | @Model: user-defined tag with name + colorHex |
| `Stores/PomodoroStore.swift` | ModelContainer + all stats aggregation queries |
| `Views/MenuBarView.swift` | Segmented tab shell; routes to section views |
| `Views/FocusView.swift` | Focus tab: TimerFaceView + cycle indicator + control knobs |
| `Views/TimerFaceView.swift` | Tomato ball visual; 5 private sub-structs; tap to toggle |
| `Views/FloatingPanelView.swift` | NSPanel SwiftUI content; drag gesture callbacks |
| `Views/StatsView.swift` | Stats tab; StatsSnapshot caching pattern |
| `Views/SettingsView.swift` | Settings tab; @Bindable var settings |
| `Views/TagManagementView.swift` | Tag CRUD |
| `Styles/AppTheme.swift` | Color tokens, animation constants, ViewModifiers |
