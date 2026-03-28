import SwiftUI

private enum TagEditorMode {
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

struct TagManagementView: View {
    @State private var editorMode: TagEditorMode?
    @State private var editorName = ""
    @State private var editorColor = AppTheme.TagPalette.writingHex
    @State private var editorFocusDuration = 25

    let store: PomodoroStore
    let onSelectTag: (Tag?) -> Void
    let selectedTag: Tag?

    private let colors = AppTheme.TagPalette.hexValues

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("tags.list")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Button("tags.new") {
                    presentCreateEditor()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.secondaryAccent)
            }

            VStack(spacing: 10) {
                ForEach(store.fetchTags()) { tag in
                    Button {
                        onSelectTag(tag)
                    } label: {
                        tagRow(
                            title: tag.name,
                            detail: "\(tag.focusDurationMinutes) \(String(localized: "unit.min"))",
                            color: AppTheme.tagColor(for: tag.colorHex),
                            isSelected: selectedTag?.id == tag.id
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("tags.editAction") {
                            presentEditEditor(for: tag)
                        }
                        if !tag.isDefault {
                            Button("tags.delete") {
                                if selectedTag?.id == tag.id,
                                   let defaultTag = store.fetchTag(id: Tag.defaultID) {
                                    onSelectTag(defaultTag)
                                }
                                store.deleteTag(tag)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay {
            if let editorMode {
                ZStack {
                    Rectangle()
                        .fill(.black.opacity(0.14))
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissEditor()
                        }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(editorMode.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            Button {
                                dismissEditor()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.muted)
                                    .frame(width: 26, height: 26)
                                    .background(AppTheme.ring)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        TextField("tags.placeholder", text: $editorName)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            ForEach(colors, id: \.self) { color in
                                Button {
                                    editorColor = color
                                } label: {
                                    Circle()
                                        .fill(AppTheme.tagColor(for: color))
                                        .frame(width: 22, height: 22)
                                        .overlay {
                                            if editorColor == color {
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

                        Stepper(value: $editorFocusDuration, in: 10...90, step: 5) {
                            HStack {
                                Text("tags.focusDuration")
                                Spacer()
                                Text("\(editorFocusDuration) \(String(localized: "unit.min"))")
                                    .foregroundStyle(AppTheme.muted)
                            }
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                        }

                        HStack(spacing: 10) {
                            Button("tags.cancel") {
                                dismissEditor()
                            }
                            .buttonStyle(.bordered)

                            Button(editorMode.primaryActionTitle) {
                                submitEditor(mode: editorMode)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.secondaryAccent)
                            .disabled(editorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.paper.opacity(0.98))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppTheme.paperShadow.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.paperShadow.opacity(0.28), radius: 20, x: 0, y: 12)
                }
                .transition(.opacity)
            }
        }
    }

    private func presentCreateEditor() {
        editorMode = .create
        editorName = ""
        editorColor = colors.first ?? AppTheme.TagPalette.writingHex
        editorFocusDuration = 25
    }

    private func presentEditEditor(for tag: Tag) {
        editorMode = .edit(tag)
        editorName = tag.name
        editorColor = tag.colorHex
        editorFocusDuration = tag.focusDurationMinutes
    }

    private func submitEditor(mode: TagEditorMode) {
        switch mode {
        case .create:
            store.createTag(name: editorName, colorHex: editorColor, focusDurationMinutes: editorFocusDuration)
        case .edit(let tag):
            store.updateTag(tag, name: editorName, colorHex: editorColor, focusDurationMinutes: editorFocusDuration)
        }
        dismissEditor()
    }

    private func dismissEditor() {
        editorMode = nil
    }

    private func tagRow(title: String, detail: String, color: Color, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(color, lineWidth: 1.5)
                            .padding(-3)
                    }
                }

            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 12)

                Text(detail)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.muted)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? color.opacity(0.12) : AppTheme.ring.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected ? color.opacity(0.95) : AppTheme.paperShadow.opacity(0.18),
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
    }
}
