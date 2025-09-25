# Build and Deploy Script for Off-Grid SOS App (Windows)

Write-Host "🚀 Building Off-Grid SOS App..." -ForegroundColor Green

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Generate code
Write-Host "🔧 Generating code..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

# Run tests
Write-Host "🧪 Running tests..." -ForegroundColor Yellow
flutter test

# Build APK for testing
Write-Host "📱 Building APK..." -ForegroundColor Yellow
flutter build apk --debug

# Create release build (if needed)
if ($args[0] -eq "release") {
    Write-Host "🏁 Building release APK..." -ForegroundColor Yellow
    flutter build apk --release
}

Write-Host "✅ Build completed!" -ForegroundColor Green

# Show build artifacts
Write-Host "📦 Build artifacts:" -ForegroundColor Cyan
Get-ChildItem -Path "build/app/outputs/flutter-apk/" -Name

# Instructions for deployment
Write-Host ""
Write-Host "📋 Deployment Instructions:" -ForegroundColor Cyan
Write-Host "1. Install on Device 1: adb install build/app/outputs/flutter-apk/app-debug.apk" -ForegroundColor White
Write-Host "2. Install on Device 2: adb install build/app/outputs/flutter-apk/app-debug.apk" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Testing Steps:" -ForegroundColor Cyan
Write-Host "Device 1 (SOS):" -ForegroundColor Yellow
Write-Host "  • Open app → Settings → Set name 'SOS_Device_1' → Choose SOS mode" -ForegroundColor White
Write-Host "  • Return to home → Tap red SOS button" -ForegroundColor White
Write-Host "  • Wait 10 seconds for advertising to start" -ForegroundColor White
Write-Host ""
Write-Host "Device 2 (Rescuer):" -ForegroundColor Yellow
Write-Host "  • Open app → Settings → Set name 'Rescuer_1' → Choose Rescuer mode" -ForegroundColor White
Write-Host "  • Return to home → Enable Rescuer Mode (blue switch)" -ForegroundColor White
Write-Host "  • Tap Devices button → Tap Scan → Wait 30 seconds" -ForegroundColor White
Write-Host "  • Should see 'SOS_Device_1' in the list" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Troubleshooting:" -ForegroundColor Cyan
Write-Host "  • Check debug logs in 'flutter logs' or Android Studio" -ForegroundColor White
Write-Host "  • Ensure both devices have Location and Bluetooth permissions" -ForegroundColor White
Write-Host "  • Keep devices within 1-10 meters for testing" -ForegroundColor White
Write-Host "  • Try restarting both apps if not detecting" -ForegroundColor White
Write-Host ""
Write-Host "📖 See TROUBLESHOOTING.md for detailed troubleshooting guide" -ForegroundColor Cyan

# Pause to let user read the instructions
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")