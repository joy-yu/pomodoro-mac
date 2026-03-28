# Coding Patterns

## @Observable + @Bindable

`TimerEngine` and `AppSettings` use `@Observable` (Swift 5.9). When a view needs two-way bindings, declare `@Bindable` at the use site — do not write manual `Binding(get:set:)` wrappers.

```swift
// Correct
struct SettingsView: View {
    @Bindable var settings: AppSettings
    // Stepper(value: $settings.workDurationMinutes, ...)
}

// Wrong
Binding(get: { settings.workDurationMinutes }, set: { settings.workDurationMinutes = $0 })
```

Callers pass the object as a plain `let`; `@Bindable` is only needed where bindings are created.

## Stats Caching (StatsSnapshot)

Never call `PomodoroStore` directly inside `body` — each body evaluation would trigger a DB query. Use the snapshot pattern:

```swift
@State private var cache: StatsSnapshot?

var body: some View {
    // render from cache only
}
.task { loadStats() }
.onAppear { loadStats() }   // re-runs on every tab switch

private func loadStats() {
    cache = StatsSnapshot(
        pomodorosToday: store.completedPomodorosToday(),
        // ... all queries in one assignment
    )
}
```

## Large View Decomposition

Views over ~80 lines should be split into `private struct` sub-views within the same file. Keep the main `body` under 25 lines.

Reference: `TimerFaceView.swift` — 5 private structs: `TimerFaceBallLayer`, `TimerFaceProgressRing`, `TimerFaceInnerSphere`, `TimerFaceContent`, `TimerFaceHoverControl`.

## MainActor Isolation

`TimerEngine`, `AppSettings`, and `FloatingPanelManager` run on `@MainActor`. Delegate callbacks are `nonisolated` by default — always bridge back explicitly:

```swift
nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    Task { @MainActor in
        completionHandler(shouldPlaySound ? [.banner, .sound, .list] : [.banner, .list])
    }
}
```

## SwiftData Schema Migration

Any change to a persisted field on a `@Model` class — adding, removing, or renaming — causes SwiftData to fail loading the existing store with `loadIssueModelContainer`. Schema evolution must be declared via `VersionedSchema` + `SchemaMigrationPlan`.

### During development (no data to preserve)

Delete the store files and relaunch:

```bash
rm ~/Library/Application\ Support/default.store*
```

### Change type reference

| Change                                     | Strategy                                             |
| ------------------------------------------ | ---------------------------------------------------- |
| Add field (with default value or optional) | Lightweight migration                                |
| Remove field                               | Lightweight migration                                |
| Rename field                               | `@Attribute(.originalName:)` + Lightweight migration |
| Type change / data transform               | Custom migration                                     |

### Lightweight Migration (add / remove / rename)

**Step 1** — Create `Models/SchemaVersions.swift` and freeze each historical model snapshot:

```swift
// Models/SchemaVersions.swift

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Tag.self, PomodoroSession.self] }

    @Model final class Tag {
        @Attribute(.unique) var id: UUID
        var name: String
        var colorHex: String
        var focusDurationMinutes: Int
        // no isDefault
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Tag.self, PomodoroSession.self] }

    @Model final class Tag {
        @Attribute(.unique) var id: UUID
        var name: String
        var colorHex: String
        var focusDurationMinutes: Int
        var isDefault: Bool   // new field — must have a default value
    }
}
```

**Step 2** — Declare the migration plan:

```swift
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [v1ToV2] }

    static let v1ToV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

**Step 3** — Pass the migration plan into `PomodoroStore.init`:

```swift
container = try ModelContainer(
    for: schema,
    migrationPlan: AppMigrationPlan.self,
    configurations: [configuration]
)
```

### Renaming a field

Annotate the new property with its original column name; SwiftData maps it automatically during lightweight migration:

```swift
// SchemaV3
@Attribute(.originalName: "focusDurationMinutes")
var durationMinutes: Int
```

### Custom Migration (data transform required)

Use `MigrationStage.custom` when the field type changes or old values need to be computed:

```swift
static let v2ToV3 = MigrationStage.custom(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self,
    willMigrate: nil,
    didMigrate: { context in
        let tags = try context.fetch(FetchDescriptor<Tag>())
        tags.forEach { $0.someNewField = computeFrom($0) }
        try context.save()
    }
)
```

### Checklist for every `@Model` field change

1. Freeze the current model as a new `SchemaVN` enum (only models with persisted fields need snapshotting)
2. Choose lightweight vs. custom migration
3. Append the new version to `AppMigrationPlan.schemas` and `stages`
4. Update `PomodoroStore`'s `ModelContainer` init to pass `migrationPlan:` (one-time change; subsequent schema bumps only touch `AppMigrationPlan`)

## FloatingPanelManager.configure

`configure(engine:settings:)` must be called once before any `updateVisibility` call. Subsequent `show()` / `hide()` calls require no parameters — the manager holds the references internally.

```swift
// PomodoroApp.init()
floatingPanelManager.configure(engine: engine, settings: settings)
DispatchQueue.main.async {
    floatingPanelManager.updateVisibility(isVisible: settings.floatingPanelVisible)
}
```
