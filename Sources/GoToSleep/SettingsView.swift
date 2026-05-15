import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: SleepPreferences

    let onDone: () -> Void

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
