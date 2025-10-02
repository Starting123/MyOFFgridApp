@echo off
echo 🧪 OFF-GRID SOS APP - QUICK TEST SUITE
echo ===============================================
echo.

echo 📱 Phase 1: Checking Flutter setup...
flutter doctor --android-licenses > nul 2>&1
flutter devices

echo.
echo 🔥 Phase 2: Checking Firebase connection...
firebase projects:list 2>nul
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not setup. Run: npm install -g firebase-tools
) else (
    echo ✅ Firebase CLI ready
)

echo.
echo 🏗️ Phase 3: Building app...
flutter clean
flutter pub get

echo.
echo 🚀 Phase 4: Starting app...
echo Choose testing mode:
echo 1. Run on default device
echo 2. Run on specific device
echo 3. Run tests only
echo 4. Start Firebase emulators
echo.

set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo Starting app on default device...
    flutter run
) else if "%choice%"=="2" (
    echo Available devices:
    flutter devices
    echo.
    set /p device="Enter device ID: "
    flutter run -d !device!
) else if "%choice%"=="3" (
    echo Running unit tests...
    flutter test
) else if "%choice%"=="4" (
    echo Starting Firebase emulators...
    start "Firebase Emulators" firebase emulators:start
    timeout /t 5 /nobreak > nul
    echo Starting app with emulators...
    flutter run --dart-define=USE_FIREBASE_EMULATOR=true
) else (
    echo Invalid choice. Starting default...
    flutter run
)

pause