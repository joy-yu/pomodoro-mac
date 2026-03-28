import SwiftUI

enum TimerFaceDisplayMode {
    case regular
    case compact
}

private struct TimerFaceMetrics {
    let outerRingLineWidth: CGFloat
    let outerRingPadding: CGFloat
    let trackLineWidth: CGFloat
    let dashLineWidth: CGFloat
    let endCapSize: CGFloat
    let endCapOffset: CGFloat
    let innerFacePadding: CGFloat
    let iconSize: CGFloat
    let timeSize: CGFloat
    let titleSize: CGFloat
    let badgeSize: CGFloat
    let contentSpacing: CGFloat

    static let regular = TimerFaceMetrics(
        outerRingLineWidth: 12,
        outerRingPadding: 12,
        trackLineWidth: 15,
        dashLineWidth: 2,
        endCapSize: 20,
        endCapOffset: 95,
        innerFacePadding: 40,
        iconSize: 16,
        timeSize: 42,
        titleSize: 16,
        badgeSize: 10,
        contentSpacing: 8
    )

    static let compact = TimerFaceMetrics(
        outerRingLineWidth: 9,
        outerRingPadding: 10,
        trackLineWidth: 11,
        dashLineWidth: 1.5,
        endCapSize: 15,
        endCapOffset: 72,
        innerFacePadding: 34,
        iconSize: 12,
        timeSize: 24,
        titleSize: 12,
        badgeSize: 8,
        contentSpacing: 6
    )
}

private struct TimerFaceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(AppTheme.Animation.facePress, value: configuration.isPressed)
    }
}

// MARK: - Subviews

private struct TimerFaceBallLayer: View {
    let metrics: TimerFaceMetrics

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppTheme.tomato.opacity(0.98), AppTheme.tomatoDark],
                    center: .topLeading,
                    startRadius: 8,
                    endRadius: 180
                )
            )
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.paper.opacity(0.14),
                                .clear,
                                AppTheme.tomatoDark.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            )
            .overlay(
                Circle()
                    .stroke(AppTheme.ring.opacity(0.62), lineWidth: metrics.outerRingLineWidth)
                    .padding(metrics.outerRingPadding)
            )
            .shadow(color: AppTheme.tomatoDark.opacity(0.35), radius: 8, x: 0, y: 8)
    }
}

private struct TimerFaceProgressRing: View {
    let metrics: TimerFaceMetrics
    let clampedProgress: Double
    let progressGradient: AngularGradient
    let progressColor: Color
    let isRunning: Bool

    private var progressPadding: CGFloat {
        let outerChannelEdge = metrics.outerRingPadding + metrics.outerRingLineWidth / 2
        let innerChannelEdge = metrics.innerFacePadding - 0.5
        return (outerChannelEdge + innerChannelEdge) / 2
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AppTheme.ring.opacity(0.12),
                    style: StrokeStyle(lineWidth: metrics.dashLineWidth, lineCap: .round, dash: [1, 9])
                )
                .padding(progressPadding)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: metrics.trackLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(progressPadding)
                .shadow(
                    color: progressColor.opacity(isRunning ? 0.18 : 0.1),
                    radius: isRunning ? 5 : 2,
                    x: 0, y: 0
                )
                .animation(AppTheme.Animation.progressRing, value: clampedProgress)
        }
    }
}

private struct TimerFaceInnerSphere: View {
    let metrics: TimerFaceMetrics
    let strokeWidth: CGFloat
    let isHovering: Bool

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        AppTheme.tomato.opacity(isHovering ? 0.62 : 0.55),
                        AppTheme.tomatoDark.opacity(isHovering ? 0.84 : 0.92)
                    ],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 120
                )
            )
            .padding(metrics.innerFacePadding)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.paper.opacity(isHovering ? 0.2 : 0.08),
                                .clear,
                                AppTheme.paper.opacity(isHovering ? 0.08 : 0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(metrics.innerFacePadding)
                    .blendMode(.screen)
            )
            .overlay(
                Circle()
                    .stroke(AppTheme.paper.opacity(isHovering ? 0.09 : 0.05), lineWidth: strokeWidth)
                    .padding(metrics.innerFacePadding)
            )
            .animation(AppTheme.Animation.innerFaceHover, value: isHovering)
    }
}

private struct TimerFaceContent: View {
    let engine: TimerEngine
    let metrics: TimerFaceMetrics

    var body: some View {
        VStack(spacing: metrics.contentSpacing) {
            Image(systemName: engine.currentPhase.symbolName)
                .font(.system(size: metrics.iconSize, weight: .semibold))
                .foregroundStyle(AppTheme.ring)
                .accessibilityHidden(true)

            Text(engine.formattedRemainingTime)
                .font(.system(size: metrics.timeSize, weight: .bold, design: .serif))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(engine.currentPhaseDisplayTitle)
                .font(.system(size: metrics.titleSize, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ring.opacity(0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                ForEach(0..<engine.cycleStageCount, id: \.self) { index in
                    Image(systemName: index < engine.filledBadgesInCycle ? "seal.fill" : "seal")
                        .font(.system(size: metrics.badgeSize))
                        .foregroundStyle(AppTheme.ring.opacity(index < engine.filledBadgesInCycle ? 1 : 0.35))
                }
            }
            .accessibilityLabel(String(format: String(localized: "a11y.completedPomodoros"), engine.completedPomodoros))
        }
    }
}

private struct TimerFaceHoverControl: View {
    let engine: TimerEngine
    let isHovering: Bool
    let size: KnobControlSize

    private var symbolName: String {
        engine.state == .running ? "pause.fill" : "play.fill"
    }

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size.iconSize, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.tomatoDark)
            .frame(width: size.diameter, height: size.diameter)
            .contentShape(Circle())
            .knobSurface(isHovered: isHovering)
            .opacity(isHovering ? 1 : 0)
            .scaleEffect(isHovering ? 1.03 : 0.94)
            .animation(AppTheme.Animation.hoverOverlay, value: isHovering)
            .animation(AppTheme.Animation.symbolSwitch, value: symbolName)
    }
}

// MARK: - TimerFaceView

struct TimerFaceView: View {
    let engine: TimerEngine
    private let displayMode: TimerFaceDisplayMode
    @State private var isHoveringFace = false

    init(engine: TimerEngine, displayMode: TimerFaceDisplayMode = .regular) {
        self.engine = engine
        self.displayMode = displayMode
    }

    private var metrics: TimerFaceMetrics {
        displayMode == .regular ? .regular : .compact
    }

    private var clampedProgress: Double {
        min(max(engine.progress, 0), 1)
    }

    private var progressColor: Color {
        switch engine.currentPhase {
        case .work:       return AppTheme.phaseWork
        case .shortBreak: return AppTheme.phaseShortBreak
        case .longBreak:  return AppTheme.phaseLongBreak
        }
    }

    private var progressHighlightColor: Color {
        switch engine.currentPhase {
        case .work:       return AppTheme.phaseWorkHigh
        case .shortBreak: return AppTheme.phaseShortBreakHigh
        case .longBreak:  return AppTheme.phaseLongBreakHigh
        }
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [
                progressHighlightColor,
                progressColor.opacity(0.9),
                progressColor,
                progressColor.opacity(0.88),
                progressHighlightColor.opacity(0.92)
            ],
            center: .center
        )
    }

    private var hoverControlAccessibilityLabel: String {
        engine.state == .running ? String(localized: "a11y.pause") : String(localized: "a11y.start")
    }

    var body: some View {
        Button {
            engine.toggle()
        } label: {
            ZStack {
                TimerFaceBallLayer(metrics: metrics)
                TimerFaceProgressRing(
                    metrics: metrics,
                    clampedProgress: clampedProgress,
                    progressGradient: progressGradient,
                    progressColor: progressColor,
                    isRunning: engine.state == .running
                )
                TimerFaceInnerSphere(metrics: metrics, strokeWidth: 1, isHovering: isHoveringFace)
                TimerFaceContent(engine: engine, metrics: metrics)
                TimerFaceHoverControl(
                    engine: engine,
                    isHovering: isHoveringFace,
                    size: displayMode == .regular ? .regular : .compact
                )
            }
        }
        .buttonStyle(TimerFaceButtonStyle())
        .accessibilityLabel(hoverControlAccessibilityLabel)
        .contentShape(Circle())
        .onHover { isHoveringFace = $0 }
        .aspectRatio(1, contentMode: .fit)
    }
}
