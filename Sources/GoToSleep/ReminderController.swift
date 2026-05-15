import AppKit
import GoToSleepCore
import SwiftUI

@MainActor
final class ReminderController {
    private let margin: CGFloat = 18
    private let height: CGFloat = 158
    private let preferredWidth: CGFloat = 320

    private var panels: [ReminderPanel] = []
    private var screenSignatures: [String] = []
    private var currentPhase: SleepPhase = .none
    private var currentSchedule: BedtimeSchedule?
    private var currentScheduleDescription = ""

    func show(phase: SleepPhase, schedule: BedtimeSchedule, scheduleDescription: String) {
        let screens = NSScreen.screens
        let signatures = screens.map { NSStringFromRect($0.visibleFrame) }

        if panels.count != screens.count || screenSignatures != signatures {
            rebuild()
            panels = screens.map {
                makePanel(
                    for: $0,
                    phase: phase,
                    schedule: schedule,
                    scheduleDescription: scheduleDescription
                )
            }
            screenSignatures = signatures
        }

        if currentPhase != phase || currentSchedule != schedule || currentScheduleDescription != scheduleDescription {
            updateContent(phase: phase, schedule: schedule, scheduleDescription: scheduleDescription)
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
        currentPhase = .none
        currentSchedule = nil
        currentScheduleDescription = ""
    }

    func rebuild() {
        hide()
    }

    private func makePanel(
        for screen: NSScreen,
        phase: SleepPhase,
        schedule: BedtimeSchedule,
        scheduleDescription: String
    ) -> ReminderPanel {
        let width = panelWidth(for: screen)
        let panel = ReminderPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        panel.contentView = NSHostingView(rootView: ReminderView(
            phase: phase,
            schedule: schedule,
            scheduleDescription: scheduleDescription
        ))
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

    private func updateContent(phase: SleepPhase, schedule: BedtimeSchedule, scheduleDescription: String) {
        currentPhase = phase
        currentSchedule = schedule
        currentScheduleDescription = scheduleDescription

        panels.forEach { panel in
            panel.contentView = NSHostingView(rootView: ReminderView(
                phase: phase,
                schedule: schedule,
                scheduleDescription: scheduleDescription
            ))
        }
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
        min(preferredWidth, max(292, screen.visibleFrame.width - margin * 2))
    }
}

final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct ReminderView: View {
    let phase: SleepPhase
    let schedule: BedtimeSchedule
    let scheduleDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(clockString(for: context.date))
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundStyle(foregroundColor)
                        .lineLimit(1)
                        .monospacedDigit()

                    if let sleepLossDescription = sleepLossDescription(for: context.date) {
                        Text(sleepLossDescription)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(foregroundColor.opacity(0.86))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(foregroundColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(scheduleDescription)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(foregroundColor.opacity(0.82))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(foregroundColor.opacity(0.24), lineWidth: 1)
        )
        .padding(1)
    }

    private var title: String {
        switch phase {
        case .none:
            "Go To Sleep"
        case .windDown:
            "Wind down for bed"
        case .bedtime:
            "It's time for bed"
        }
    }

    private var iconName: String {
        switch phase {
        case .none, .bedtime:
            "bed.double.fill"
        case .windDown:
            "moon.zzz.fill"
        }
    }

    private var backgroundColor: Color {
        switch phase {
        case .none, .bedtime:
            Color(red: 0.82, green: 0.1, blue: 0.12)
        case .windDown:
            Color(red: 1.0, green: 0.78, blue: 0.18)
        }
    }

    private var foregroundColor: Color {
        switch phase {
        case .none, .bedtime:
            .white
        case .windDown:
            Color(red: 0.18, green: 0.12, blue: 0.02)
        }
    }

    private func clockString(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(
            format: "%02d:%02d:%02d",
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }

    private func sleepLossDescription(for date: Date) -> String? {
        let minute = BedtimeSchedule.minuteOfDay(for: date)
        guard let sleepLossMinutes = schedule.roundedSleepLossMinutes(minuteOfDay: minute) else {
            return nil
        }

        return "Losing \(durationDescription(minutes: sleepLossMinutes)) of sleep"
    }

    private func durationDescription(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        let hourDescription = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteDescription = remainingMinutes == 1
            ? "1 minute"
            : "\(remainingMinutes) minutes"

        if hours == 0 {
            return minuteDescription
        }

        if remainingMinutes == 0 {
            return hourDescription
        }

        return "\(hourDescription), \(minuteDescription)"
    }
}
