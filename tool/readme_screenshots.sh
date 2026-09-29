#!/usr/bin/env bash
# Regenerates the README screenshots in docs/screenshots/.
#
# Usage: tool/readme_screenshots.sh <booted-ios-simulator-udid>
#
# Runs integration_test/readme/readme_screenshots_test.dart against a fresh
# in-memory database and, each time the test prints README_SHOT:<name>,
# saves a real simulator screenshot as docs/screenshots/<name>.png.
set -euo pipefail

device="${1:?pass a booted iOS simulator UDID (xcrun simctl list devices booted)}"
out="docs/screenshots"
mkdir -p "$out"

xcrun simctl status_bar "$device" override --time "9:41" \
  --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

fvm flutter drive \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/readme/readme_screenshots_test.dart \
  -d "$device" 2>&1 | while IFS= read -r line; do
  echo "$line"
  if [[ "$line" =~ README_SHOT:([a-z_]+) ]]; then
    name="${BASH_REMATCH[1]}"
    sleep 1
    xcrun simctl io "$device" screenshot --type=png "$out/$name.png" >/dev/null 2>&1
    echo "  -> saved $out/$name.png"
  fi
done

xcrun simctl status_bar "$device" clear
