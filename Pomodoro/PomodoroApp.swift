import SwiftData
import SwiftUI

@main
struct PomodoroApp: App {
    @State private var store: PomodoroStore
    @State private var settings: AppSettings
    @State private var notifications: NotificationManager
    @State private var floatingPanelManager: FloatingPanelManager
    @State private var engine: TimerEngine
    @State private var selectedSection: MenuSection = .focus

    init() {
        AppSettings.applyLanguagePreference()

        let store = PomodoroStore()
        let settings = AppSettings()
        let notifications = NotificationManager()
        let floatingPanelManager = FloatingPanelManager()
        let engine = TimerEngine(settings: settings, store: store, notifications: notifications)

        store.syncPresetTagNames()
        engine.restoreSelectedTag()

        notifications.requestAuthorizationIfNeeded()

        floatingPanelManager.configure(engine: engine, settings: settings)

        _store = State(initialValue: store)
        _settings = State(initialValue: settings)
        _notifications = State(initialValue: notifications)
        _floatingPanelManager = State(initialValue: floatingPanelManager)
        _engine = State(initialValue: engine)

        DispatchQueue.main.async {
            floatingPanelManager.updateVisibility(isVisible: settings.floatingPanelVisible)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                selectedSection: $selectedSection,
                settings: settings,
                floatingPanelManager: floatingPanelManager,
                store: store,
                engine: engine
            )
            .frame(width: 400, height: 640)
            .modelContainer(store.container)
            .colorScheme(.light)
        } label: {
            Label("\(engine.menuBarTitle)", systemImage: engine.currentPhase.symbolName)
                .labelStyle(.titleAndIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
