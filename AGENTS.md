# AGENTS.md

Native macOS menu bar Pomodoro app — SwiftUI + SwiftData + AppKit + Swift Charts.

## Tech Stack

- SwiftUI app lifecycle, `@Observable` (Swift 5.9, **not** ObservableObject)
- SwiftData for persistence, Swift Charts for analytics
- AppKit for floating panel window management
- UserNotifications for phase alerts
- XcodeGen — `project.yml` is the canonical project definition

Deployment target: macOS 14. No third-party dependencies.

## Repository Layout

```
Pomodoro/
├── PomodoroApp.swift          # @main, dependency assembly
├── FloatingPanelManager.swift # NSPanel lifecycle + drag
├── Engine/                    # Timer state machine, notifications, settings
├── Models/                    # SwiftData models and enums
├── Stores/                    # Persistence + stats aggregation
├── Views/                     # All SwiftUI views
└── Styles/                    # AppTheme: colors, animations, ViewModifiers

project.yml                    # XcodeGen spec — edit this, not pbxproj
doc/                           # Detailed architecture and design docs
```

## Build & Run

```bash
xcodegen generate   # required after adding/removing files or editing project.yml
./scripts auto-build-after-save.sh
```

## Working Rules

1. Edit `project.yml`, not `pbxproj`. Run `xcodegen generate` after structural changes.
2. Build and confirm `BUILD SUCCEEDED` after every code change.
3. New Swift files go under `Pomodoro/` — XcodeGen picks them up via glob.
4. Use SwiftUI first; AppKit only where native window behavior is required.
5. Prefer `@Observable` + `@Bindable` over ObservableObject patterns.
6. All colors and animations must go through `AppTheme` — no inline literals.
7. Keep changes focused; do not refactor code outside the task scope.
8. Read `doc/architecture.md` and relevant view files before making non-trivial changes.
9. Keep documentation in sync: update `doc/` whenever features change or requirements evolve — file responsibilities, architecture flows, and coding patterns must reflect the current state of the code.
10. Any user-facing text change must be applied to all four `Localizable.strings` files. Never hardcode display strings in Swift — use `String(localized:)` or `LocalizedStringKey` and add the corresponding keys to every locale file. Keep translations concise: prefer the shortest phrasing that still preserves precise semantic meaning, especially for UI labels where space is constrained.
