import AppKit
import SwiftUI

@MainActor
final class ReminderController {
    private let margin: CGFloat = 18
    private let height: CGFloat = 92
    private let preferredWidth: CGFloat = 360

    private var panels: [ReminderPanel] = []
    private var screenSignatures: [String] = []

    func show(scheduleDescription: String) {
        let screens = NSScreen.screens
        let signatures = screens.map { NSStringFromRect($0.visibleFrame) }

        if panels.count != screens.count || screenSignatures != signatures {
            rebuild()
            panels = screens.map { makePanel(for: $0, scheduleDescription: scheduleDescription) }
            screenSignatures = signatures
        }

        for (panel, screen) in zip(panels, screens) {
            position(panel, on: screen)
            panel.orderFrontRegardless()
        }
    }

    func hide() {
        panels.forEach { panel in
            panel.orderOut(nil)
            panel.close()
        }
        panels.removeAll()
        screenSignatures.removeAll()
    }

    func rebuild() {
        hide()
    }

    private func makePanel(for screen: NSScreen, scheduleDescription: String) -> ReminderPanel {
        let width = panelWidth(for: screen)
        let panel = ReminderPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        panel.contentView = NSHostingView(rootView: ReminderView(scheduleDescription: scheduleDescription))
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = .statusBar
        panel.canHide = false

        position(panel, on: screen)
        return panel
    }

    private func position(_ panel: NSPanel, on screen: NSScreen) {
        let frame = screen.visibleFrame
        let width = panelWidth(for: screen)
        panel.setFrame(
            NSRect(
                x: frame.maxX - width - margin,
                y: frame.maxY - height - margin,
                width: width,
                height: height
            ),
            display: true
        )
    }

    private func panelWidth(for screen: NSScreen) -> CGFloat {
        min(preferredWidth, max(260, screen.visibleFrame.width - margin * 2))
    }
}

final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct ReminderView: View {
    let scheduleDescription: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("It's time for bed")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(scheduleDescription)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.82, green: 0.1, blue: 0.12).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .padding(1)
    }
}
