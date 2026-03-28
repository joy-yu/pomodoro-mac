import AppKit
import SwiftUI

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class FloatingPanelManager {
    private var panel: NSPanel?
    private var dragBaseOrigin: CGPoint?
    private var dragBaseMouseLocation: CGPoint?
    private var engine: TimerEngine?
    private var settings: AppSettings?

    func configure(engine: TimerEngine, settings: AppSettings) {
        self.engine = engine
        self.settings = settings
    }

    func updateVisibility(isVisible: Bool) {
        if isVisible {
            show()
        } else {
            hide()
        }
    }

    func show() {
        guard let engine, let settings else { return }

        let isCreatingPanel = panel == nil

        if panel == nil {
            let newPanel = FloatingPanel(
                contentRect: NSRect(x: 0, y: 0, width: 236, height: 266),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.isMovableByWindowBackground = false
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = false
            newPanel.level = .floating
            newPanel.hidesOnDeactivate = false
            newPanel.isReleasedWhenClosed = false
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let contentView = FloatingPanelView(
                engine: engine,
                settings: settings,
                onHide: { [weak self] in
                    self?.settings?.floatingPanelVisible = false
                    self?.hide()
                },
                onPanelDrag: { [weak self, weak newPanel] in
                    guard let self, let panel = newPanel else { return }
                    let mouseNow = NSEvent.mouseLocation
                    if self.dragBaseOrigin == nil {
                        self.dragBaseOrigin = panel.frame.origin
                        self.dragBaseMouseLocation = mouseNow
                    }
                    guard let base = self.dragBaseOrigin,
                          let baseMouse = self.dragBaseMouseLocation else { return }
                    panel.setFrameOrigin(CGPoint(
                        x: base.x + (mouseNow.x - baseMouse.x),
                        y: base.y + (mouseNow.y - baseMouse.y)
                    ))
                },
                onPanelDragEnd: { [weak self] in
                    self?.dragBaseOrigin = nil
                    self?.dragBaseMouseLocation = nil
                }
            )
            let hostingController = NSHostingController(rootView: contentView)
            newPanel.contentViewController = hostingController
            panel = newPanel
        }

        panel?.orderFront(nil)

        if isCreatingPanel, let panel {
            DispatchQueue.main.async { [weak self, weak panel] in
                guard let self, let panel else { return }
                panel.contentView?.layoutSubtreeIfNeeded()
                self.positionPanelAtRightEdge(panel)
            }
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func positionPanelAtRightEdge(_ panel: NSPanel) {
        guard let screenFrame = targetScreen()?.visibleFrame else { return }

        let proposedX = screenFrame.maxX - panel.frame.width
        let proposedY = screenFrame.midY - (panel.frame.height / 2)

        let origin = NSPoint(
            x: min(max(proposedX, screenFrame.minX), screenFrame.maxX - panel.frame.width),
            y: min(max(proposedY, screenFrame.minY), screenFrame.maxY - panel.frame.height)
        )

        panel.setFrameOrigin(origin)
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }
}
