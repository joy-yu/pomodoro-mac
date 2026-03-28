import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @State private var showRestartHint = false

    var body: some View {
        Form {

            Section("settings.timing") {
                HStack(alignment: .center) {
                    row(title: String(localized: "settings.shortBreak"),
                        value: "\(settings.shortBreakMinutes) \(String(localized: "unit.min"))")
                    Stepper("", value: $settings.shortBreakMinutes, in: 3...30, step: 1)
                        .labelsHidden()
                }

                HStack(alignment: .center) {
                    row(title: String(localized: "settings.longBreak"),
                        value: "\(settings.longBreakMinutes) \(String(localized: "unit.min"))")
                    Stepper("", value: $settings.longBreakMinutes, in: 10...45, step: 5)
                        .labelsHidden()
                }

                HStack(alignment: .center) {
                    row(title: String(localized: "settings.longBreakInterval"),
                        value: String(format: String(localized: "settings.longBreakIntervalDesc"), settings.longBreakInterval))
                    Stepper("", value: $settings.longBreakInterval, in: 2...6, step: 1)
                        .labelsHidden()
                }
            }

            Section("settings.behavior") {
                Toggle("settings.autoStart", isOn: $settings.autoStartNextPhase)
                Toggle("settings.notifications", isOn: $settings.notificationsEnabled)
                Toggle("settings.sound", isOn: $settings.soundEnabled)
                Toggle("settings.floatingPanel", isOn: $settings.floatingPanelVisible)
            }

            Section("settings.other") {
                Picker("settings.language", selection: $settings.appLanguage) {
                    Text("settings.languageSystem").tag("")
                    Text(verbatim: "English").tag("en")
                    Text(verbatim: "简体中文").tag("zh-Hans")
                    Text(verbatim: "繁體中文").tag("zh-Hant")
                    Text(verbatim: "日本語").tag("ja")
                }
                .pickerStyle(.menu)
                .onChange(of: settings.appLanguage) { _, _ in
                    showRestartHint = true
                }

                if showRestartHint {
                    HStack(alignment: .center) {
                        Text("settings.languageRestartHint")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.muted)
                        Spacer()
                        Button("settings.restartNow", action: restartApp)
                            .buttonStyle(.borderless)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }

            Section("settings.about") {
                row(title: String(localized: "settings.version"), value: appVersion)
                row(title: String(localized: "settings.developer"), value: "joy-yu")
                HStack {
                    Text(verbatim: "GitHub")
                    Spacer()
                    Link("github.com/joy-yu", destination: URL(string: "https://github.com/joy-yu")!)
                        .foregroundStyle(AppTheme.accent)
                }
                Text(verbatim: "© \(copyrightYear) joy-yu")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .formStyle(.grouped)
        .tint(AppTheme.accent)
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    private var copyrightYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.bundlePath)
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApplication.shared.terminate(nil) }
        }
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
