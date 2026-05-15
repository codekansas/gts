# Go To Sleep

Go To Sleep is a tiny macOS menu-bar app. Configure wind-down and bedtime ranges from the status item, and while either range is active the app keeps a floating reminder visible in the top-right corner:

> It's time for bed

Wind-down defaults to 9:15 PM - 9:30 PM and shows a yellow reminder. Bedtime defaults to 9:30 PM - 6:00 AM and shows a red reminder.

The reminder ignores mouse events, so it does not block clicks or typing in other apps. While a reminder is active, the app disables its normal Quit command and re-shows the reminder if the app is hidden.

Use the menu-bar dropdown to toggle `Open at Login` after installing the app.

## Development

Run it directly:

```sh
swift run GoToSleep
```

Build a double-clickable menu-bar app bundle:

```sh
./scripts/build_app.sh
open "dist/Go To Sleep.app"
```

Run local checks:

```sh
swift run GoToSleepChecks
```

On machines with only the macOS Command Line Tools installed, local
`swift test` can fail with a missing `XCTest` module. GitHub Actions selects
Xcode before running the normal `swift test` workflow.

## CI and Releases

- Pull requests and pushes run the `unit-tests` GitHub Actions workflow.
- Published GitHub Releases run the `release` workflow, which builds a `.app`,
  packages a `.zip`, and uploads the `.zip` plus a SHA-256 checksum to the
  release.
- GitHub release builds require `APPLE_DEVELOPER_ID_APPLICATION_P12` and
  `APPLE_DEVELOPER_ID_APPLICATION_P12_PASSWORD`, then sign the app with
  Developer ID.
- If GitHub Actions also has `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and
  `APPLE_TEAM_ID` configured, the release workflow notarizes the `.app` and
  staples the notarization ticket before packaging.
- The manual `app-store` workflow builds a Mac App Store `.pkg` and can upload
  it to App Store Connect. It requires
  `APPLE_MAC_APP_DISTRIBUTION_P12`,
  `APPLE_MAC_APP_DISTRIBUTION_P12_PASSWORD`,
  `APPLE_MAC_APP_DISTRIBUTION_IDENTITY`,
  `APPLE_MAC_INSTALLER_DISTRIBUTION_P12`,
  `APPLE_MAC_INSTALLER_DISTRIBUTION_P12_PASSWORD`,
  `APPLE_MAC_INSTALLER_DISTRIBUTION_IDENTITY`,
  `APPLE_MAC_APP_STORE_PROVISIONING_PROFILE`,
  `APP_STORE_CONNECT_API_KEY_ID`,
  `APP_STORE_CONNECT_API_ISSUER_ID`, and
  `APP_STORE_CONNECT_API_PRIVATE_KEY`.
