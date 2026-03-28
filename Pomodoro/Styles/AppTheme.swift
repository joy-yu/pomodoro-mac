import SwiftUI

enum AppTheme {
    // Base palette
    static let tomatoHex = "#C6543F"
    static let tomatoDarkHex = "#9C3D2E"
    static let oliveHex = "#60734B"
    static let paperHex = "#F7F0E8"
    static let paperShadowHex = "#D9C7B8"
    static let inkHex = "#35251D"
    static let mutedHex = "#8C7567"
    static let ringHex = "#FDF8F2"

    static let paper = Color(hex: paperHex)
    static let paperShadow = Color(hex: paperShadowHex)
    static let tomato = Color(hex: tomatoHex)
    static let tomatoDark = Color(hex: tomatoDarkHex)
    static let olive = Color(hex: oliveHex)
    static let ink = Color(hex: inkHex)
    static let muted = Color(hex: mutedHex)
    static let ring = Color(hex: ringHex)
    static let accent = tomato
    static let secondaryAccent = olive

    // Phase accent colors — shared by timer face, cycle indicators
    static let phaseWork      = Color(hex: "#B8872A")
    static let phaseWorkHigh  = Color(hex: "#ECC058")
    static let phaseShortBreak     = Color(hex: "#5E8A58")
    static let phaseShortBreakHigh = Color(hex: "#98C286")
    static let phaseLongBreak      = Color(hex: "#3A7068")
    static let phaseLongBreakHigh  = Color(hex: "#6AA898")

    enum TagPalette {
        static let writingHex = AppTheme.tomatoHex
        static let designHex = "#A66C3D"
        static let codingHex = "#6B4E3D"
        static let readingHex = "#3F6C63"
        static let reviewHex = "#8B5A46"
        static let planningHex = AppTheme.oliveHex

        static let hexValues = [writingHex, designHex, codingHex, readingHex, reviewHex, planningHex]
    }

    static func tagColor(for hex: String) -> Color {
        Color(hex: hex)
    }

    enum Animation {
        static let knobPress      = SwiftUI.Animation.spring(duration: 0.22, bounce: 0.2)
        static let knobHover      = SwiftUI.Animation.spring(duration: 0.24, bounce: 0.18)
        static let facePress      = SwiftUI.Animation.spring(duration: 0.22, bounce: 0.16)
        static let progressRing   = SwiftUI.Animation.spring(duration: 0.5,  bounce: 0.16)
        static let innerFaceHover = SwiftUI.Animation.easeOut(duration: 0.18)
        static let hoverOverlay   = SwiftUI.Animation.spring(duration: 0.24, bounce: 0.16)
        static let symbolSwitch   = SwiftUI.Animation.spring(duration: 0.3,  bounce: 0.2)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let red, green, blue: UInt64
        switch hex.count {
        case 6:
            (red, green, blue) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (red, green, blue) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

struct PaperPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.paper, AppTheme.paper.opacity(0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.72), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func paperPanel() -> some View {
        modifier(PaperPanelModifier())
    }
}

enum KnobControlSize {
    case regular
    case compact

    var diameter: CGFloat {
        switch self {
        case .regular:
            return 46
        case .compact:
            return 34
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .regular:
            return 18
        case .compact:
            return 13
        }
    }
}

struct KnobSurfaceModifier: ViewModifier {
    let isPressed: Bool
    let isHovered: Bool

    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isPressed
                                ? [AppTheme.paperShadow, AppTheme.paper]
                                : isHovered
                                    ? [AppTheme.ring, AppTheme.paper]
                                    : [AppTheme.ring, AppTheme.paperShadow.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(isHovered ? 0.82 : 0.6), lineWidth: 1)
                    )
                    .shadow(
                        color: AppTheme.paperShadow.opacity(isPressed ? 0.2 : isHovered ? 0.5 : 0.45),
                        radius: isPressed ? 4 : isHovered ? 12 : 10,
                        x: isPressed ? 2 : 6,
                        y: isPressed ? 2 : 6
                    )
            )
    }
}

extension View {
    func knobSurface(isPressed: Bool = false, isHovered: Bool = false) -> some View {
        modifier(KnobSurfaceModifier(isPressed: isPressed, isHovered: isHovered))
    }
}

struct KnobButtonStyle: ButtonStyle {
    let size: KnobControlSize

    init(size: KnobControlSize = .regular) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        KnobButtonStyleView(configuration: configuration, size: size)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private struct KnobButtonStyleView: View {
    let configuration: ButtonStyle.Configuration
    let size: KnobControlSize
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: size.iconSize, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.tomatoDark)
            .frame(width: size.diameter, height: size.diameter)
            .contentShape(Circle())
            .knobSurface(isPressed: configuration.isPressed, isHovered: isHovered)
            .scaleEffect(configuration.isPressed ? 0.96 : isHovered ? 1.03 : 1)
            .brightness(isHovered ? 0.01 : 0)
            .animation(AppTheme.Animation.knobPress, value: configuration.isPressed)
            .animation(AppTheme.Animation.knobHover, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
