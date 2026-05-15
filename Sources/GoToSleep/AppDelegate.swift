import AppKit
import Combine
import GoToSleepCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let preferences = SleepPreferences()
    private let reminderController = ReminderController()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    private var activeMenuItem: NSMenuItem?
    private var windDownMenuItem: NSMenuItem?
    private var bedtimeMenuItem: NSMenuItem?
    private var quitMenuItem: NSMenuItem?
    private var settingsWindow: NSWindow?
    private var timer: Timer?
    private var preferencesCancellable: AnyCancellable?
    private var activePhase: SleepPhase = .none

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        observeSystemChanges()

        preferencesCancellable = preferences.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.evaluateSchedule()
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateSchedule()
            }
        }

        evaluateSchedule()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        evaluateSchedule()
        return isReminderActive ? .terminateCancel : .terminateNow
    }

    func applicationDidHide(_ notification: Notification) {
        evaluateSchedule()
        if isReminderActive {
            NSApp.unhide(nil)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "bed.double.fill",
                accessibilityDescription: "Go To Sleep"
            )
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: "Go To Sleep", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        activeMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        activeMenuItem?.isEnabled = false
        menu.addItem(activeMenuItem!)

        windDownMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        windDownMenuItem?.isEnabled = false
        menu.addItem(windDownMenuItem!)

        bedtimeMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        bedtimeMenuItem?.isEnabled = false
        menu.addItem(bedtimeMenuItem!)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Go To Sleep",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitMenuItem = quitItem
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenu()
    }

    private func observeSystemChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    private func updateMenu() {
        activeMenuItem?.title = switch activePhase {
        case .none:
            "Reminder inactive"
        case .windDown:
            "Wind-down reminder active"
        case .bedtime:
            "Bedtime reminder active"
        }
        windDownMenuItem?.title = "Wind down: \(preferences.windDownDescription)"
        bedtimeMenuItem?.title = "Bedtime: \(preferences.bedtimeDescription)"
        quitMenuItem?.isEnabled = !isReminderActive
        quitMenuItem?.title = isReminderActive
            ? "Quit disabled while reminder is active"
            : "Quit Go To Sleep"
    }

    private func evaluateSchedule() {
        activePhase = preferences.schedule.phase(date: Date())

        switch activePhase {
        case .none:
            reminderController.hide()
        case .windDown:
            reminderController.show(
                phase: .windDown,
                scheduleDescription: preferences.windDownDescription
            )
        case .bedtime:
            reminderController.show(
                phase: .bedtime,
                scheduleDescription: preferences.bedtimeDescription
            )
        }

        updateMenu()
        settingsWindow?.contentView = NSHostingView(rootView: SettingsView(
            preferences: preferences,
            onDone: { [weak self] in self?.settingsWindow?.close() }
        ))
    }

    private var isReminderActive: Bool {
        activePhase != .none
    }

    @objc private func screenParametersChanged() {
        reminderController.rebuild()
        evaluateSchedule()
    }

    @objc private func activeSpaceChanged() {
        evaluateSchedule()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 430, height: 286),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Go To Sleep"
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.delegate = self
            settingsWindow = window
        }

        evaluateSchedule()
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === settingsWindow else {
            return
        }
        settingsWindow = nil
    }
}
