import SwiftUI

struct TagManagementView: View {
    let store: PomodoroStore
    let onSelectTag: (Tag?) -> Void
    let onPresentCreate: () -> Void
    let onPresentEdit: (Tag) -> Void
    let selectedTag: Tag?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("tags.list")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Button("tags.new") {
                    onPresentCreate()
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
                        .overlay(alignment: .trailing) {
                            Menu {
                                Button("tags.editAction") {
                                    onPresentEdit(tag)
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
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                    .frame(width: 26, height: 26)
                                    .background(AppTheme.ring)
                                    .clipShape(Circle())
                                    .contentShape(Rectangle().size(CGSize(width: 44, height: 44)))
                            }
                            .menuStyle(.borderlessButton)
                            .menuIndicator(.hidden)
                            .fixedSize()
                            .tint(AppTheme.ink)
                            .padding(.trailing, 10)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.muted)

            Spacer(minLength: 0)

            // reserved space for the ellipsis menu button
            Color.clear.frame(width: 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(isSelected ? color.opacity(0.12) : AppTheme.ring.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .stroke(
                    isSelected ? color.opacity(0.95) : AppTheme.paperShadow.opacity(0.18),
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
    }
}
