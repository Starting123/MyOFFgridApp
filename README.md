# MyOFFgridApp - Off-Grid SOS Communication App

A Flutter-based emergency communication app designed for off-grid scenarios using peer-to-peer networking, BLE, and cloud sync capabilities.

## 📱 Overview

MyOFFgridApp is an emergency communication system that enables users to send SOS messages and communicate in areas with limited or no internet connectivity. The app uses multiple communication channels including:

- **Peer-to-Peer (P2P)** networking via nearby devices
- **Bluetooth Low Energy (BLE)** for short-range communication
- **Cloud synchronization** when internet is available
- **Background services** for continuous operation

## 🏗️ Architecture

### Core Components

1. **Database Layer** (Drift ORM)
   - Local SQLite database for message and device storage
   - Offline-first architecture with sync capabilities
   - Message and device tables with companion classes

2. **State Management** (Riverpod 3.0)
   - Reactive state management using Notifier pattern
   - Providers for chat, nearby devices, and connection states
   - AsyncValue handling for loading/error states

3. **Communication Services**
   - **P2PService**: Nearby Connections API for device discovery and messaging
   - **BLEService**: Bluetooth Low Energy for short-range communication
   - **CloudSync**: HTTP-based cloud synchronization
   - **SyncService**: Orchestrates offline/online sync

4. **Background Processing**
   - **WorkManager**: For periodic sync tasks
   - **Flutter Foreground Task**: Keeps services running
   - **Encryption Service**: Message security using PointyCastle

## 🚀 Features

- ✅ **SOS Mode**: Emergency broadcasting to nearby devices
- ✅ **Rescuer Mode**: Receive and respond to SOS messages
- ✅ **P2P Messaging**: Direct device-to-device communication
- ✅ **Offline Storage**: Messages stored locally with Drift database
- ✅ **Background Sync**: Automatic cloud synchronization when online
- ✅ **Encrypted Communication**: Secure message transmission
- ⚠️ **BLE Communication**: Partially implemented (license issue)
- ⚠️ **Background Services**: May have compatibility issues with some plugins

## 🛠️ Setup Instructions

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Android device or emulator (API level 23+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd MyOFFgridApp
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate database code:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Build Configuration

The app requires minimum Android API level 23 due to plugin requirements. Key build settings:

- **minSdk**: 23 (required for flutter_foreground_task)
- **targetSdk**: Latest Flutter target
- **compileSdk**: Latest Flutter compile SDK
- **NDK Version**: 27.0.12077973

## 📦 Dependencies

### Core Dependencies
```yaml
flutter:
  sdk: flutter
flutter_riverpod: ^2.3.6    # State management
drift: ^2.28.2               # Database ORM
drift_flutter: ^0.2.0       # Flutter integration for Drift
nearby_connections: ^4.3.0   # P2P communication
flutter_blue_plus: ^1.32.12  # Bluetooth Low Energy
workmanager: ^0.5.2         # Background tasks
flutter_foreground_task: ^6.5.0  # Foreground services
```

### Additional Dependencies
- `http`: HTTP requests for cloud sync
- `crypto` & `pointycastle`: Encryption
- `permission_handler`: Runtime permissions
- `path_provider`: File system access

### Dev Dependencies
- `build_runner`: Code generation
- `drift_dev`: Database code generation
- `json_serializable`: JSON serialization

## 🔧 Configuration

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Cloud Configuration

Update `lib/src/utils/constants.dart`:

```dart
class Constants {
  static const String cloudEndpoint = 'https://your-api-endpoint.com/api';
  // Add other configuration constants
}
```

## 🚨 Current Issues & Limitations

### Known Issues

1. **BLE Service License Parameter**: The flutter_blue_plus connection requires a license parameter that needs proper implementation
2. **WorkManager Compatibility**: Build failures due to plugin compatibility with current Flutter version
3. **Background Service Lifecycle**: Some background tasks may not persist across app restarts

### Limitations

- **Android Only**: iOS implementation not included
- **Cloud Endpoint**: Requires backend API for cloud sync
- **Range Limitations**: P2P and BLE have limited range (typically 100m)
- **Battery Optimization**: May be affected by device power management

## 📝 Usage Guide

### Starting the App

1. **Choose Mode**: Select SOS or Rescuer mode on the home screen
2. **Grant Permissions**: Allow location, Bluetooth, and nearby device permissions
3. **Discovery**: App automatically discovers nearby devices
4. **Communication**: Send messages or respond to SOS alerts

### SOS Mode

- Broadcasts emergency signal to nearby devices
- Automatic retry with exponential backoff
- Messages stored locally and synced when online

### Rescuer Mode

- Listens for SOS signals
- Can respond to emergency messages
- Maintain communication with SOS devices

## 🔐 Security

- **Message Encryption**: All messages encrypted using PointyCastle
- **Local Storage**: Database secured with device encryption
- **P2P Security**: Nearby Connections API provides device authentication
- **Cloud Transport**: HTTPS for all cloud communication

## 📊 Database Schema

### Messages Table
```sql
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  receiver_id TEXT,
  is_sos BOOLEAN DEFAULT 0,
  timestamp DATETIME NOT NULL,
  is_synced BOOLEAN DEFAULT 0
);
```

### Devices Table
```sql
CREATE TABLE devices (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  last_seen DATETIME NOT NULL,
  device_type TEXT NOT NULL  -- 'sos' or 'rescuer'
);
```

## 🧪 Testing

### Running Tests
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Debug Mode
```bash
# Run in debug mode with logs
flutter run --debug --verbose
```

## 📈 Future Improvements

### Planned Features
- [ ] iOS support
- [ ] Mesh network topology for extended range
- [ ] Voice message support
- [ ] GPS location sharing
- [ ] Group messaging
- [ ] Message delivery confirmations

### Technical Improvements
- [ ] Fix BLE service licensing
- [ ] Resolve workmanager compatibility
- [ ] Implement proper background service lifecycle
- [ ] Add comprehensive test coverage
- [ ] Performance optimizations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and support:
- Check existing GitHub issues
- Create new issue with detailed description
- Include device info and logs for bug reports

## ⚠️ Disclaimer

This app is designed for emergency communication scenarios. While it provides multiple communication channels, it should not be the sole means of emergency communication. Always have backup emergency plans and devices when in remote areas.

---

**Version**: 1.0.0  
**Last Updated**: September 24, 2025  
**Flutter Version**: 3.0+  
**Minimum Android**: API 23 (Android 6.0)
