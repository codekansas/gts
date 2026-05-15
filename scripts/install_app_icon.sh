#!/usr/bin/env bash
set -euo pipefail

icon_source_path="$1"
resources_dir="$2"
icon_file_name="${3:-GoToSleep.icns}"
scratch_dir="${4:-}"

if [[ ! -f "$icon_source_path" ]]; then
  echo "Missing icon source: $icon_source_path" >&2
  exit 1
fi

if [[ -z "$scratch_dir" ]]; then
  scratch_dir="$(mktemp -d)"
  cleanup_scratch=1
else
  cleanup_scratch=0
  rm -rf "$scratch_dir"
  mkdir -p "$scratch_dir"
fi

mkdir -p "$resources_dir"

iconset_path="$scratch_dir/${icon_file_name%.icns}.iconset"
rm -rf "$iconset_path"
mkdir -p "$iconset_path"

sips -z 16 16 "$icon_source_path" --out "$iconset_path/icon_16x16.png" >/dev/null
sips -z 32 32 "$icon_source_path" --out "$iconset_path/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$icon_source_path" --out "$iconset_path/icon_32x32.png" >/dev/null
sips -z 64 64 "$icon_source_path" --out "$iconset_path/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$icon_source_path" --out "$iconset_path/icon_128x128.png" >/dev/null
sips -z 256 256 "$icon_source_path" --out "$iconset_path/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$icon_source_path" --out "$iconset_path/icon_256x256.png" >/dev/null
sips -z 512 512 "$icon_source_path" --out "$iconset_path/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$icon_source_path" --out "$iconset_path/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$icon_source_path" --out "$iconset_path/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$iconset_path" -o "$resources_dir/$icon_file_name"

if [[ "$cleanup_scratch" == "1" ]]; then
  rm -rf "$scratch_dir"
fi
