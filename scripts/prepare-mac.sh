#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS builds require macOS and Xcode. The Swift core can be tested on Windows."
  exit 1
fi
# Resource conversion for Apple's exact app-icon dimensions; preserve the generated master.
sips -z 1024 1024 App/Resources/Assets.xcassets/AppIcon.appiconset/icon.png --out App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png >/dev/null
if ! command -v xcodegen >/dev/null; then
  echo "Install XcodeGen with: brew install xcodegen"
  exit 1
fi
xcodegen generate
python3 scripts/prepare-testplan.py
echo "Open PlanBridgeAI.xcodeproj, select your signing team, then run on iPhone or iPad."
