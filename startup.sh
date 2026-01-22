# 1. Open Simulator and boot device
open -a Simulator
xcrun simctl boot "iPhone 17 Pro"

# 2. Build the app
xcodebuild -project WarpDriveApp/WarpDriveApp.xcodeproj -scheme WarpDriveApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/warpdrive-build build

# 3. Install and launch
xcrun simctl install "iPhone 17 Pro" "/tmp/warpdrive-build/Build/Products/Debug-iphonesimulator/WarpDriveApp.app"
xcrun simctl launch "iPhone 17 Pro" com.warpdrive.app
