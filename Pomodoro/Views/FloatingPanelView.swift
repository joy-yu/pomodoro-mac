import SwiftUI

struct FloatingPanelView: View {
    let engine: TimerEngine
    let settings: AppSettings
    let onHide: () -> Void
    let onPanelDrag: () -> Void
    let onPanelDragEnd: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TimerFaceView(engine: engine, displayMode: .compact)
                .frame(width: 176, height: 176)

            HStack(spacing: 12) {
                Button {
                    engine.toggle()
                } label: {
                    Image(systemName: engine.state == .running ? "pause.fill" : "play.fill")
                }
                .buttonStyle(KnobButtonStyle(size: .compact))

                Button {
                    onHide()
                } label: {
                    Image(systemName: "eye.slash.fill")
                }
                .buttonStyle(KnobButtonStyle(size: .compact))
                .accessibilityLabel(String(localized: "a11y.hidePanel"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.clear)
        .colorScheme(.light)
        .highPriorityGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { _ in
                    onPanelDrag()
                }
                .onEnded { _ in
                    onPanelDragEnd()
                }
        )
    }
}
