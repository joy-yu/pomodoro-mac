import SwiftUI

struct FocusView: View {
    let engine: TimerEngine

    private var stageAccent: Color {
        switch engine.currentPhase {
        case .work:       return AppTheme.phaseWork
        case .shortBreak: return AppTheme.phaseShortBreak
        case .longBreak:  return AppTheme.phaseLongBreak
        }
    }

    private var focusTagColor: Color {
        if let selectedTag = engine.selectedTag {
            return Color(hex: selectedTag.colorHex)
        }
        return AppTheme.paperShadow
    }

    var body: some View {
        VStack(spacing: 36) {
            TimerFaceView(engine: engine)
                .frame(width: 250)
                .padding(.top, 4)

            HStack(spacing: 8) {
                Circle()
                    .fill(focusTagColor)
                    .frame(width: 8, height: 8)

                Text(engine.effectiveFocusTitle)

                Text("·   \(engine.effectiveFocusDurationMinutes) \(String(localized: "unit.min"))")
                    .foregroundStyle(AppTheme.muted)

                Spacer(minLength: 12)

                HStack(spacing: 7) {
                    ForEach(1...engine.cycleStageCount, id: \.self) { stage in
                        Capsule(style: .continuous)
                            .fill(stage <= engine.cycleStageIndex ? stageAccent : AppTheme.paperShadow.opacity(0.55))
                            .frame(
                                width: stage == engine.cycleStageIndex ? 16 : 10,
                                height: stage == engine.cycleStageIndex ? 9 : 6
                            )
                            .overlay {
                                if stage == engine.cycleStageIndex {
                                    Capsule(style: .continuous)
                                        .stroke(.white.opacity(0.5), lineWidth: 0.8)
                                }
                            }
                            .opacity(stage < engine.cycleStageIndex ? 0.45 : 1)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(format: String(localized: "a11y.cycleStage"), engine.cycleStageIndex, engine.cycleStageCount))
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous)
                    .fill(AppTheme.ring.opacity(0.86))
            )

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
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
