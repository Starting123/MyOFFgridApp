#!/bin/bash

# Build and Deploy Script for Off-Grid SOS App

set -e

echo "🚀 Building Off-Grid SOS App..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Generate code
echo "🔧 Generating code..."
dart run build_runner build --delete-conflicting-outputs

# Run tests
echo "🧪 Running tests..."
flutter test

# Build APK for testing
echo "📱 Building APK..."
flutter build apk --debug

# Create release build (if needed)
if [[ "$1" == "release" ]]; then
    echo "🏁 Building release APK..."
    flutter build apk --release
fi

echo "✅ Build completed!"

# Show build artifacts
echo "📦 Build artifacts:"
ls -la build/app/outputs/flutter-apk/

# Instructions for deployment
echo ""
echo "📋 Deployment Instructions:"
echo "1. Install on Device 1: adb install build/app/outputs/flutter-apk/app-debug.apk"
echo "2. Install on Device 2: adb install build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "🧪 Testing Steps:"
echo "Device 1 (SOS):"
echo "  • Open app → Settings → Set name 'SOS_Device_1' → Choose SOS mode"
echo "  • Return to home → Tap red SOS button"
echo "  • Wait 10 seconds for advertising to start"
echo ""
echo "Device 2 (Rescuer):"
echo "  • Open app → Settings → Set name 'Rescuer_1' → Choose Rescuer mode"
echo "  • Return to home → Enable Rescuer Mode (blue switch)"
echo "  • Tap Devices button → Tap Scan → Wait 30 seconds"
echo "  • Should see 'SOS_Device_1' in the list"
echo ""
echo "🔧 Troubleshooting:"
echo "  • Check debug logs in 'flutter logs' or Android Studio"
echo "  • Ensure both devices have Location and Bluetooth permissions"
echo "  • Keep devices within 1-10 meters for testing"
echo "  • Try restarting both apps if not detecting"
echo ""
echo "📖 See TROUBLESHOOTING.md for detailed troubleshooting guide"