import SwiftUI

enum TagEditorMode {
    case create
    case edit(Tag)

    var title: String {
        switch self {
        case .create:
            return String(localized: "tags.new")
        case .edit:
            return String(localized: "tags.edit")
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .create:
            return String(localized: "tags.create")
        case .edit:
            return String(localized: "tags.saveChanges")
        }
    }
}

/// Full-screen overlay sheet for creating or editing a Tag.
/// Owns its own field state; pre-fills from the tag when editing.
struct TagEditorSheet: View {
    let mode: TagEditorMode
    let store: PomodoroStore
    let onDismiss: () -> Void

    @State private var name: String
    @State private var colorHex: String
    @State private var focusDuration: Int

    private let colors = AppTheme.TagPalette.hexValues

    init(mode: TagEditorMode, store: PomodoroStore, onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.store = store
        self.onDismiss = onDismiss

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _colorHex = State(initialValue: AppTheme.TagPalette.hexValues.first ?? AppTheme.TagPalette.writingHex)
            _focusDuration = State(initialValue: 25)
        case .edit(let tag):
            _name = State(initialValue: tag.name)
            _colorHex = State(initialValue: tag.colorHex)
            _focusDuration = State(initialValue: tag.focusDurationMinutes)
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.panel, style: .continuous))
                .onTapGesture { onDismiss() }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(mode.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.muted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                TextField("tags.placeholder", text: $name)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            colorHex = color
                        } label: {
                            Circle()
                                .fill(AppTheme.tagColor(for: color))
                                .frame(width: 22, height: 22)
                                .overlay {
                                    if colorHex == color {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundStyle(.white)
                                            .background(
                                                Circle()
                                                    .fill(Color.black.opacity(0.22))
                                                    .frame(width: 14, height: 14)
                                            )
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Stepper(value: $focusDuration, in: 10...90, step: 5) {
                    HStack {
                        Text("tags.focusDuration")
                        Spacer()
                        Text("\(focusDuration) \(String(localized: "unit.min"))")
                            .foregroundStyle(AppTheme.muted)
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                }

                HStack(spacing: 10) {
                    Button("tags.cancel") { onDismiss() }
                        .buttonStyle(.bordered)
                    Button(mode.primaryActionTitle) { submit() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.secondaryAccent)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(18)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .fill(AppTheme.paper.opacity(0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .stroke(AppTheme.paperShadow.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: AppTheme.paperShadow.opacity(0.28), radius: 20, x: 0, y: 12)
        }
        .transition(.opacity)
    }

    private func submit() {
        switch mode {
        case .create:
            store.createTag(name: name, colorHex: colorHex, focusDurationMinutes: focusDuration)
        case .edit(let tag):
            store.updateTag(tag, name: name, colorHex: colorHex, focusDurationMinutes: focusDuration)
        }
        onDismiss()
    }
}
