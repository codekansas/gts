import GoToSleepCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: SleepPreferences

    @State private var isLaunchAtLoginEnabled: Bool

    let launchAtLoginStatus: LaunchAtLoginStatus
    let onLaunchAtLoginChanged: (Bool) -> Void
    let onDone: () -> Void

    init(
        preferences: SleepPreferences,
        launchAtLoginStatus: LaunchAtLoginStatus,
        onLaunchAtLoginChanged: @escaping (Bool) -> Void,
        onDone: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.launchAtLoginStatus = launchAtLoginStatus
        self.onLaunchAtLoginChanged = onLaunchAtLoginChanged
        self.onDone = onDone
        self._isLaunchAtLoginEnabled = State(initialValue: launchAtLoginStatus.isEnabled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Schedule")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 14) {
                DatePicker(
                    "Wind down",
                    selection: $preferences.windDownStartDate,
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "Bedtime",
                    selection: $preferences.bedtimeStartDate,
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    "Wake",
                    selection: $preferences.bedtimeEndDate,
                    displayedComponents: .hourAndMinute
                )
            }

            Toggle(
                launchAtLoginStatus.isAvailable
                    ? "Open at login"
                    : "Open at login unavailable",
                isOn: $isLaunchAtLoginEnabled
            )
            .toggleStyle(.checkbox)
            .disabled(!launchAtLoginStatus.isAvailable)
            .onChange(of: isLaunchAtLoginEnabled) { isEnabled in
                onLaunchAtLoginChanged(isEnabled)
            }

            HStack {
                Text(preferences.scheduleDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .frame(height: 22)

            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 430)
    }
}
