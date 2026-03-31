import SwiftUI

struct FocusView: View {
    let engine: TimerEngine
    let store: PomodoroStore
    let onNewTag: () -> Void

    @State private var showTagPicker = false
    @State private var showDurationPicker = false

    private var selectedTagColor: Color {
        if let tag = engine.selectedTag { return AppTheme.tagColor(for: tag.colorHex) }
        return AppTheme.paperShadow
    }

    var body: some View {
        VStack(spacing: 20) {

            TimerFaceView(engine: engine)
                .frame(width: 250)
                .padding(.top, 4)

            HStack(spacing: 18) {
                Button {
                    engine.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(KnobButtonStyle(size: .regular))
                .accessibilityLabel(String(localized: "a11y.reset"))

                Button {
                    engine.toggle()
                } label: {
                    Image(systemName: engine.state == .running ? "pause.fill" : "play.fill")
                }
                .buttonStyle(KnobButtonStyle(size: .regular))
                .accessibilityLabel(engine.state == .running ? String(localized: "a11y.pause") : String(localized: "a11y.start"))

                Button {
                    engine.skipToNextPhase()
                } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(KnobButtonStyle(size: .regular))
                .accessibilityLabel(String(localized: "a11y.skipPhase"))
            }

            controlRow
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var controlRow: some View {
        HStack(spacing: 0) {
            // Tag dropdown
            Button {
                showTagPicker.toggle()
            } label: {
                HStack(spacing: 7) {
                    Circle()
                        .fill(selectedTagColor)
                        .frame(width: 7, height: 7)
                    Text(engine.effectiveFocusTitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.leading, 12)
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showTagPicker, arrowEdge: .bottom) {
                TagPickerPopover(
                    tags: store.fetchTags(),
                    selectedTag: engine.selectedTag,
                    onSelect: { tag in
                        engine.selectTag(tag)
                        showTagPicker = false
                    },
                    onNewTag: {
                        showTagPicker = false
                        onNewTag()
                    }
                )
            }

            // Divider
            Rectangle()
                .fill(AppTheme.paperShadow.opacity(0.25))
                .frame(width: 1, height: 20)
                .padding(.horizontal, 4)

            // Duration dropdown
            Button {
                showDurationPicker.toggle()
            } label: {
                HStack(spacing: 6) {
                    Text("\(engine.effectiveFocusDurationMinutes) \(String(localized: "unit.min"))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(engine.state == .running ? AppTheme.muted : AppTheme.ink)
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(engine.state == .running)
            .popover(isPresented: $showDurationPicker, arrowEdge: .bottom) {
                DurationPickerPopover(
                    selected: engine.effectiveFocusDurationMinutes,
                    onSelect: { minutes in
                        engine.setFocusDuration(minutes)
                        showDurationPicker = false
                    }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.ring.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .stroke(AppTheme.paperShadow.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct DurationPickerPopover: View {
    let selected: Int
    let onSelect: (Int) -> Void

    private static let durations = stride(from: 10, through: 90, by: 5).map { $0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(Self.durations, id: \.self) { minutes in
                    let isSelected = minutes == selected
                    Button {
                        onSelect(minutes)
                    } label: {
                        HStack {
                            Text("\(minutes) \(String(localized: "unit.min"))")
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? AppTheme.accent.opacity(0.08) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(width: 120, height: min(CGFloat(Self.durations.count) * 34 + 16, 280))
    }
}

private struct TagPickerPopover: View {
    let tags: [Tag]
    let selectedTag: Tag?
    let onSelect: (Tag) -> Void
    let onNewTag: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(tags) { tag in
                let tagColor = AppTheme.tagColor(for: tag.colorHex)
                let isSelected = selectedTag?.id == tag.id

                Button {
                    onSelect(tag)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(tagColor)
                            .frame(width: 8, height: 8)
                            .overlay {
                                if isSelected {
                                    Circle()
                                        .stroke(tagColor, lineWidth: 1.5)
                                        .padding(-3)
                                }
                            }

                        Text(tag.name)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(tagColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? tagColor.opacity(0.10) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.horizontal, 8)
                .padding(.vertical, 2)

            Button {
                onNewTag()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryAccent)
                    Text("tags.new")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryAccent)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(minWidth: 180)
    }
}
