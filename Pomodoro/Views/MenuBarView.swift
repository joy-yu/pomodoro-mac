import SwiftUI

enum MenuSection: String, CaseIterable, Identifiable {
    case focus
    case tags
    case stats
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:
            return String(localized: "menu.focus")
        case .stats:
            return String(localized: "menu.stats")
        case .tags:
            return String(localized: "menu.tags")
        case .settings:
            return String(localized: "menu.settings")
        }
    }
}

struct MenuBarView: View {
    @Binding var selectedSection: MenuSection

    let settings: AppSettings
    let floatingPanelManager: FloatingPanelManager
    let store: PomodoroStore
    let engine: TimerEngine

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pomodoro")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("menu.tagline")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: $selectedSection) {
                ForEach(MenuSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)

            sectionShell(for: selectedSection) {
                switch selectedSection {
                case .focus:
                    FocusView(engine: engine)
                case .stats:
                    StatsView(store: store)
                case .tags:
                    TagManagementView(store: store, onSelectTag: { engine.selectTag($0) }, selectedTag: engine.selectedTag)
                case .settings:
                    SettingsView(settings: settings)
                }
            }
        }
        .padding(20)
        .tint(AppTheme.accent)
        .background(
            LinearGradient(
                colors: [AppTheme.paper.opacity(0.96), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onChange(of: settings.floatingPanelVisible) { _, newValue in
            floatingPanelManager.updateVisibility(isVisible: newValue)
        }
    }


    private func sectionShell<Content: View>(for section: MenuSection, @ViewBuilder content: () -> Content) -> some View {
        Group {
            if section == .focus {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(20)
            } else {
                ScrollView {
                   content()
                    .frame(maxWidth: .infinity,alignment: .topLeading)
                    .padding(20)
                }
            }
        }
        .paperPanel()
    }
}
