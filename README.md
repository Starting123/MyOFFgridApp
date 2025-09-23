# Off-Grid SOS & Nearby Share App

A Flutter application designed for emergency communication and file sharing in areas with limited or no internet connectivity. This app enables peer-to-peer communication through various technologies including WiFi Direct, Bluetooth Low Energy (BLE), and nearby connections.

## Features

### 🆘 SOS Mode
- Emergency distress signal broadcasting
- Automatic device discovery for rescuers
- Real-time location sharing (when GPS available)
- Offline message queuing and synchronization

### 👥 Rescuer Mode
- Search and connect to devices in distress
- Receive SOS signals from nearby devices
- Coordinate rescue efforts with other rescuers
- Message relay between devices

### 💬 Communication
- Real-time messaging between connected devices
- Message persistence with local database
- Automatic message synchronization when connectivity is restored
- End-to-end encryption for secure communication

### 🔗 Connectivity Options
- **Nearby Connections**: Google's nearby connections API for device discovery
- **Bluetooth Low Energy**: For low-power device communication
- **WiFi Direct**: High-speed peer-to-peer communication
- **Background Services**: Continuous scanning and connectivity

## Architecture

### Core Components

#### Data Layer (`lib/src/data/`)
- **Database (`db.dart`)**: Drift ORM for local data persistence
  - Messages table for chat history
  - Devices table for nearby device tracking
  - Automatic schema generation with `db.g.dart`

#### Services Layer (`lib/src/services/`)
- **P2P Service**: Peer-to-peer communication using Google Nearby Connections
- **BLE Service**: Bluetooth Low Energy communication and device discovery
- **WiFi Direct Service**: Direct WiFi communication between devices
- **Encryption Service**: End-to-end encryption using ECDH key exchange
- **Sync Services**: Cloud sync and peer-to-peer synchronization
- **Background Services**: Continuous scanning and discovery

#### State Management (`lib/src/providers/`)
- **Riverpod 3.0**: Modern state management with providers
- **Chat Provider**: Manages message state and real-time updates
- **Nearby Providers**: Device discovery and connection state
- **App Providers**: Global app state and configuration

#### User Interface (`lib/src/ui/screens/`)
- **Home Screen**: Main interface with SOS button and mode selection
- **Chat Screen**: Real-time messaging interface
- **SOS Screen**: Emergency broadcast interface

### Technical Stack

- **Flutter SDK**: 3.0+
- **State Management**: Riverpod 3.0 with providers
- **Database**: Drift ORM with SQLite
- **Networking**: Nearby Connections, BLE, WiFi Direct
- **Encryption**: PointyCastle for ECDH and AES encryption
- **Background Tasks**: WorkManager and Flutter Foreground Task
- **Build System**: build_runner for code generation

## Setup Instructions

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.0 or higher
   ```bash
   flutter --version  # Should be 3.0+
   ```

2. **Android Studio/VS Code**: With Flutter and Dart plugins
3. **Android Device**: Physical device required for testing (emulators have limited P2P support)

### Installation

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd MyOFFgridApp
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Code**
   ```bash
   dart run build_runner build
   ```

4. **Android Configuration**
   
   Add permissions to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.BLUETOOTH" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
   <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
   ```

5. **Build and Run**
   ```bash
   flutter run --release
   ```

## Usage Guide

### First Time Setup

1. **Launch the App**: The app will request necessary permissions
2. **Grant Permissions**: Allow location, Bluetooth, and WiFi permissions
3. **Choose Mode**: Select either SOS mode (for emergencies) or Rescuer mode

### SOS Mode (Emergency Users)

1. **Activate SOS**: Tap the large red SOS button on the home screen
2. **Broadcasting**: The app automatically broadcasts distress signals
3. **Wait for Rescuers**: Nearby rescuers will receive your SOS signal
4. **Communicate**: Send messages when rescuers connect

### Rescuer Mode

1. **Enable Rescuer Mode**: Toggle the rescuer switch on the home screen
2. **Scan for SOS**: The app continuously scans for emergency signals
3. **Connect to SOS Devices**: Tap on detected devices to establish communication
4. **Coordinate**: Use chat to communicate with people in distress

### Background Operation

The app continues scanning and can receive connections even when:
- App is in background
- Device screen is off
- Other apps are running

## Configuration

### App Settings

- **Service Timeout**: Connection timeout duration
- **Scan Interval**: How frequently to scan for devices
- **Message Retention**: How long to keep old messages
- **Encryption Settings**: Security configuration

### Performance Tuning

- **Battery Optimization**: Disable battery optimization for continuous operation
- **Network Settings**: Configure WiFi and Bluetooth scanning intervals
- **Storage Management**: Regular cleanup of old messages and devices

## Development

### Code Generation

When modifying database schemas or data models:

```bash
# Clean existing generated files
dart run build_runner clean

# Regenerate all files
dart run build_runner build

# Watch for changes during development
dart run build_runner watch
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code quality
flutter analyze
```

### Adding New Features

1. **Services**: Add new communication protocols in `lib/src/services/`
2. **UI Screens**: Create new screens in `lib/src/ui/screens/`
3. **State Management**: Add providers in `lib/src/providers/`
4. **Database**: Extend schema in `lib/src/data/db.dart`

## Known Issues

### Current Limitations

1. **BLE Connection**: Requires license parameter fix in flutter_blue_plus
2. **iOS Support**: Limited P2P functionality on iOS due to platform restrictions
3. **Battery Usage**: Background scanning can impact battery life
4. **Range Limitations**: WiFi Direct and BLE have limited range

### Troubleshooting

**App Not Discovering Devices:**
- Check location permissions are granted
- Ensure Bluetooth and WiFi are enabled
- Verify devices are within communication range

**Messages Not Syncing:**
- Check device connectivity
- Restart the app to reset connection state
- Clear app data if database becomes corrupted

**Performance Issues:**
- Reduce scan frequency in settings
- Clear old messages and device history
- Restart device if background services become unresponsive

## Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes and test thoroughly
4. Run code analysis: `flutter analyze`
5. Submit a pull request with clear description

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable names
- Document public APIs
- Write tests for new functionality
- Keep functions focused and small

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For bug reports, feature requests, or development questions:

1. Check existing issues in the repository
2. Create a new issue with detailed description
3. Include device information and reproduction steps
4. Add relevant logs and screenshots

## Roadmap

### Planned Features

- [ ] Group messaging support
- [ ] File transfer capabilities
- [ ] Voice message support
- [ ] Improved battery optimization
- [ ] iOS platform support
- [ ] Mesh networking for extended range
- [ ] Integration with satellite communication

### Performance Improvements

- [ ] Optimize background scanning
- [ ] Implement message compression
- [ ] Add connection pooling
- [ ] Enhance error recovery
- [ ] Reduce app size and memory usage

---

**Note**: This app is designed for emergency situations and areas with limited connectivity. Always have backup communication methods available in critical situations.
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
