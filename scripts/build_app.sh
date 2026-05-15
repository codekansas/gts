#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configuration="${1:-release}"
icon_file_name="GoToSleep.icns"
icon_source_path="$repo_root/Packaging/GoToSleepIcon.png"

swift build \
  --package-path "$repo_root" \
  --configuration "$configuration"

build_dir="$(swift build \
  --package-path "$repo_root" \
  --configuration "$configuration" \
  --show-bin-path)"

app_dir="$repo_root/dist/Go To Sleep.app"
rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"

cp "$build_dir/GoToSleep" "$app_dir/Contents/MacOS/GoToSleep"
cp "$repo_root/Packaging/Info.plist" "$app_dir/Contents/Info.plist"
"$repo_root/scripts/install_app_icon.sh" \
  "$icon_source_path" \
  "$app_dir/Contents/Resources" \
  "$icon_file_name" \
  "$repo_root/dist/icon-build"
chmod +x "$app_dir/Contents/MacOS/GoToSleep"

echo "Built $app_dir"
