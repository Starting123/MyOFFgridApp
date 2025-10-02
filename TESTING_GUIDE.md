# 🧪 Complete Testing Guide for Off-Grid SOS App

## 🚀 **Quick Start Testing**

### 1. Basic App Launch Test
```bash
# Run on connected device/emulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode (performance testing)
flutter run --release
```

### 2. Device Requirements
- **Android**: API level 21+ (Android 5.0+)
- **Permissions**: Location, Bluetooth, Nearby devices, Storage
- **Hardware**: Bluetooth, WiFi, GPS recommended

## 🔬 **Testing Categories**

### A. **Unit Tests** (Code Logic)
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/device_discovery_test.dart

# Run tests with coverage
flutter test --coverage
```

### B. **Integration Tests** (App Flow)
```bash
# Run integration tests
flutter test integration_test/

# Test specific scenarios
flutter test integration_test/sos_flow_test.dart
```

### C. **Firebase Testing** (Backend)
```bash
# Start Firebase emulators
firebase emulators:start

# Test with local Firebase
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

## 📱 **Manual Testing Scenarios**

### 1. **Authentication Flow**
- [ ] Open app → Login screen appears
- [ ] Login with email/password → Success
- [ ] Logout → Returns to login screen
- [ ] Invalid credentials → Error message

### 2. **P2P Discovery & Connection**
- [ ] Enable Bluetooth & Location permissions
- [ ] Start discovery → Shows scanning indicator
- [ ] Test with 2 devices nearby → Should discover each other
- [ ] Connect to discovered device → Shows connection status
- [ ] Send test message → Appears on both devices

### 3. **SOS Functionality**
- [ ] Tap SOS button → Shows confirmation dialog
- [ ] Confirm SOS → Starts broadcasting
- [ ] Check SOS status → Shows "Broadcasting" state
- [ ] Test on nearby device → Should receive SOS alert
- [ ] Cancel SOS → Stops broadcasting

### 4. **Chat System**
- [ ] Open chat list → Shows discovered users
- [ ] Start new chat → Opens chat screen
- [ ] Send message → Appears in chat
- [ ] Receive message → Shows notification
- [ ] Test offline mode → Messages queue for later

### 5. **Settings & Preferences**
- [ ] Open settings → All options visible
- [ ] Toggle notifications → Changes saved
- [ ] Change username → Updates across app
- [ ] Test encryption settings → Security enabled
- [ ] Export data → File created successfully

## 🔧 **Technical Testing**

### A. **Network Conditions**
```bash
# Test offline mode
# Turn off WiFi and mobile data, then test:
```
- [ ] App continues working with P2P
- [ ] Messages queue when offline
- [ ] Sync when connection restored

### B. **Performance Testing**
```bash
# Profile app performance
flutter run --profile

# Check memory usage
flutter drive --target=test_driver/memory_test.dart
```

### C. **Device Permissions**
Test permission handling:
- [ ] Location permission denied → Shows explanation
- [ ] Bluetooth permission denied → Shows enable prompt
- [ ] Storage permission → File operations work

## 🔥 **Firebase Integration Testing**

### 1. **Authentication**
```bash
# Test Firebase Auth
```
- [ ] User registration → Creates Firebase user
- [ ] Login → Authenticates with Firebase
- [ ] Password reset → Sends email
- [ ] Profile sync → Data stored in Firestore

### 2. **Firestore Database**
- [ ] Create conversation → Document created
- [ ] Send message → Stored in Firestore
- [ ] Real-time updates → Messages appear instantly
- [ ] Offline persistence → Works without internet

### 3. **Cloud Storage**
- [ ] Upload file → Stored in Firebase Storage
- [ ] Download file → Retrieved successfully
- [ ] Delete file → Removed from storage

## 🐛 **Common Issues & Solutions**

### 1. **Permission Issues**
```dart
// If permissions fail, check:
// 1. Android manifest permissions
// 2. iOS Info.plist permissions
// 3. Runtime permission requests
```

### 2. **Bluetooth/P2P Issues**
```bash
# Troubleshooting:
# 1. Check device compatibility
# 2. Ensure location services enabled
# 3. Verify Bluetooth is on
# 4. Test with different devices
```

### 3. **Firebase Connection Issues**
```bash
# Debug Firebase connection:
firebase projects:list
firebase use off-grid-sos-app
flutter run --dart-define=FIREBASE_DEBUG=true
```

## 📊 **Test Automation Scripts**

### Create these test files:

#### `test/widget_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myoffgridapp/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Off-Grid SOS'), findsOneWidget);
  });
}
```

#### `integration_test/app_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myoffgridapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete app flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Test login flow
      expect(find.text('Login'), findsOneWidget);
      
      // Add more flow tests here
    });
  });
}
```

## 🎯 **Testing Checklist**

### Before Release:
- [ ] All unit tests pass
- [ ] Integration tests complete
- [ ] Manual testing on 3+ devices
- [ ] Firebase integration verified
- [ ] P2P functionality tested
- [ ] SOS system working
- [ ] Performance benchmarks met
- [ ] Security testing completed

### Performance Benchmarks:
- [ ] App launch time < 3 seconds
- [ ] P2P discovery < 10 seconds
- [ ] Message delivery < 2 seconds
- [ ] Memory usage < 100MB
- [ ] Battery drain acceptable

## 🚀 **Deployment Testing**

### Android APK Testing:
```bash
# Build release APK
flutter build apk --release

# Install and test on real device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS Testing (if applicable):
```bash
# Build iOS app
flutter build ios --release

# Test on physical iOS device via Xcode
```

---

## 📝 **Test Execution Commands**

Run these commands to start testing:

```bash
# 1. Start Firebase emulators (in separate terminal)
firebase emulators:start

# 2. Run unit tests
flutter test

# 3. Run app with hot reload for manual testing
flutter run

# 4. Run integration tests
flutter test integration_test/

# 5. Performance profiling
flutter run --profile
```

Your app is now ready for comprehensive testing! 🎉