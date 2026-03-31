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
    @State private var tagEditorMode: TagEditorMode?

    let settings: AppSettings
    let floatingPanelManager: FloatingPanelManager
    let store: PomodoroStore
    let engine: TimerEngine

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center) {
                    Text("Pomodoro")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "menu.quit"))
                }
                Text("menu.tagline")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.muted)
            }

            Picker("", selection: $selectedSection) {
                ForEach(MenuSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)

            sectionShell(for: selectedSection) {
                switch selectedSection {
                case .focus:
                    FocusView(engine: engine, store: store, onNewTag: {
                        selectedSection = .tags
                        presentTagCreate()
                    })
                case .stats:
                    StatsView(store: store)
                case .tags:
                    TagManagementView(
                        store: store,
                        onSelectTag: { engine.selectTag($0) },
                        onPresentCreate: presentTagCreate,
                        onPresentEdit: presentTagEdit,
                        selectedTag: engine.selectedTag
                    )
                case .settings:
                    SettingsView(settings: settings)
                }
            }
            .overlay {
                if selectedSection == .tags, let mode = tagEditorMode {
                    TagEditorSheet(mode: mode, store: store, onDismiss: { tagEditorMode = nil })
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


    private func presentTagCreate() {
        tagEditorMode = .create
    }

    private func presentTagEdit(_ tag: Tag) {
        tagEditorMode = .edit(tag)
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
                .id(section)
            }
        }
        .paperPanel()
    }
}
