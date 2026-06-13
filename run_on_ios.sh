#!/bin/bash
set -e

# Define paths
FLUTTER_BIN="/Users/judyj4dy.net/development/flutter/bin/flutter"
XCODE_WORKSPACE="ios/Runner.xcworkspace"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export PATH="$PATH:/Users/judyj4dy.net/.gem/ruby/2.6.0/bin"

echo -e "\033[1;36m========================================================\033[0m"
echo -e "\033[1;36m           iOS Automated Runner Script                  \033[0m"
echo -e "\033[1;36m========================================================\033[0m"

# 1. Open Xcode to configure signing
echo -e "\n\033[1;33mStep 1: Code Signing Configuration\033[0m"
echo -e "No existing code signing identities were found on your Mac's keychain."
echo -e "Opening Xcode workspace to configure your Apple ID..."

if [ -d "$XCODE_WORKSPACE" ]; then
    open "$XCODE_WORKSPACE"
else
    echo -e "\033[1;31mError: Xcode workspace not found at $XCODE_WORKSPACE\033[0m"
    exit 1
fi

echo -e "\n\033[1;32mPlease complete these steps in Xcode:\033[0m"
echo -e " 1. Click on the top-level 'Runner' icon in the left-hand sidebar."
echo -e " 2. Select the 'Runner' target under the targets list in the main window."
echo -e " 3. Click the 'Signing & Capabilities' tab."
echo -e " 4. Check 'Automatically manage signing'."
echo -e " 5. Select your Apple ID in the 'Team' dropdown (or click 'Add an Account...' to sign in)."
echo -e " 6. Plug your iOS device into your Mac via USB cable."
echo -e " 7. Make sure Developer Mode is enabled on your iOS device (Settings > Privacy & Security > Developer Mode)."

# 2. Wait for user readiness
echo -e "\n\033[1;36mOnce you have configured signing and connected your device, press [ENTER] to continue...\033[0m"
read -r

# 3. Detect connected iOS device
echo -e "\n\033[1;33mStep 2: Detecting connected iOS devices...\033[0m"
DEVICE_INFO=$($FLUTTER_BIN devices | grep "ios" || true)

if [ -z "$DEVICE_INFO" ]; then
    echo -e "\033[1;31mNo iOS devices were found by Flutter.\033[0m"
    echo -e "Please verify:"
    echo -e " - Your device is plugged in via USB."
    echo -e " - You selected 'Trust This Computer' on your device screen."
    echo -e " - Xcode successfully detects the device."
    echo -e "\nWould you like to start the iOS Simulator instead? (y/n)"
    read -r RUN_SIM
    if [[ "$RUN_SIM" =~ ^[Yy]$ ]]; then
        echo -e "Launching iOS Simulator..."
        $FLUTTER_BIN emulators --launch apple_ios_simulator
        echo -e "Waiting for simulator to boot..."
        sleep 5
        echo -e "Running on simulator..."
        $FLUTTER_BIN run -d apple_ios_simulator
        exit 0
    else
        exit 1
    fi
fi

echo -e "Detected iOS Device:\n$DEVICE_INFO"

# Extract device ID (first column or matches)
DEVICE_ID=$(echo "$DEVICE_INFO" | head -n 1 | awk -F '•' '{print $2}' | tr -d ' ')

if [ -z "$DEVICE_ID" ]; then
    # Fallback to general run (Flutter will prompt to choose)
    echo -e "\n\033[1;32mLaunching on your connected iOS device...\033[0m"
    $FLUTTER_BIN run
else
    echo -e "\n\033[1;32mLaunching on device ID: $DEVICE_ID...\033[0m"
    $FLUTTER_BIN run -d "$DEVICE_ID"
fi
