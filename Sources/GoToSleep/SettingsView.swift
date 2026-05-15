import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: SleepPreferences

    let isLocked: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Bedtime")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 14) {
                DatePicker(
                    "Starts",
                    selection: $preferences.startDate,
                    displayedComponents: .hourAndMinute
                )
                .disabled(isLocked)

                DatePicker(
                    "Ends",
                    selection: $preferences.endDate,
                    displayedComponents: .hourAndMinute
                )
                .disabled(isLocked)
            }

            HStack {
                Text(preferences.scheduleDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                if isLocked {
                    Text("Locked")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.red)
                }
            }
            .frame(height: 22)

            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 380)
    }
}
