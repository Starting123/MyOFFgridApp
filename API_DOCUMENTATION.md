# API Documentation - Off-Grid SOS & Nearby Share

## ServiceCoordinator API

The central service management system providing unified access to all communication services.

### Core Methods

```dart
// Initialize all services with fallback strategy
Future<bool> initializeAll()

// Get current service status
Map<String, bool> getServiceStatus()

// Unified device discovery stream
Stream<List<NearbyDevice>> get deviceStream

// Unified message stream
Stream<ChatMessage> get messageStream

// Send message with automatic routing
Future<bool> sendMessage(ChatMessage message)

// Broadcast emergency message
Future<bool> broadcastEmergency(String message, {double? lat, double? lng})
```

### Usage Example

```dart
// Initialize services
final coordinator = ServiceCoordinator.instance;
await coordinator.initializeAll();

// Listen to discovered devices
coordinator.deviceStream.listen((devices) {
  print('Found ${devices.length} nearby devices');
});

// Send emergency message
await coordinator.broadcastEmergency(
  'EMERGENCY: Need immediate assistance!',
  lat: 37.7749,
  lng: -122.4194,
);
```

## ErrorHandlerService API

Comprehensive error management with automatic recovery capabilities.

### Core Methods

```dart
// Report error with context
Future<void> reportError(dynamic error, StackTrace? stackTrace, {
  String? context,
  Map<String, dynamic>? additionalData,
})

// Get recovery actions for error
List<RecoveryAction> getRecoveryActions(dynamic error)

// Execute recovery action
Future<bool> executeRecovery(RecoveryAction action)

// Get error statistics
ErrorStatistics getErrorStatistics()
```

### Error Types

- **NetworkError**: Connectivity issues with automatic retry
- **ServiceError**: Service initialization failures with fallback
- **DatabaseError**: Local storage issues with data recovery
- **PermissionError**: Missing permissions with user guidance
- **UnknownError**: Unexpected errors with graceful degradation

## UI Components API

### AppButton

Production-ready button with loading states and accessibility.

```dart
AppButton(
  text: 'Send SOS',
  onPressed: () => sendSOSSignal(),
  isLoading: isProcessing,
  isEmergency: true,
  icon: Icons.emergency,
  variant: ButtonVariant.primary,
)
```

### StatusIndicator

Semantic status display with color coding.

```dart
StatusIndicator(
  status: StatusType.emergency,
  text: 'SOS Active',
  size: DesignTokens.iconMD,
)
```

### AppCard

Responsive card component with consistent styling.

```dart
AppCard(
  padding: EdgeInsets.all(DesignTokens.spaceMD),
  onTap: () => navigateToDetails(),
  child: DeviceInfo(device: nearbyDevice),
)
```

## Theme System API

### AppTheme

Material 3 theme implementation with accessibility support.

```dart
// Use in MaterialApp
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)

// Emergency theme for critical UI
Container(
  decoration: BoxDecoration(
    color: EmergencyTheme.backgroundColor,
    border: Border.all(color: EmergencyTheme.borderColor),
  ),
)
```

### Design Tokens

Consistent spacing and sizing system.

```dart
// Spacing
EdgeInsets.all(DesignTokens.spaceMD)  // 16.0
SizedBox(height: DesignTokens.spaceLG)  // 24.0

// Icons
Icon(Icons.emergency, size: DesignTokens.iconLG)  // 32.0

// Radius
BorderRadius.circular(DesignTokens.radiusMD)  // 12.0
```

## Accessibility API

### AccessibilityHelper

Comprehensive accessibility support utilities.

```dart
// Announce to screen readers
AccessibilityHelper.announce(context, 'Device discovered');

// Emergency announcements
AccessibilityHelper.announceEmergency(context, 'SOS signal received');

// Check accessibility features
if (AccessibilityHelper.isHighContrastEnabled) {
  // Adjust UI for high contrast
}

// Create accessible button
AccessibilityHelper.createAccessibleButton(
  child: Text('Emergency'),
  onPressed: activateEmergency,
  semanticLabel: 'Activate emergency mode',
)
```

## Responsive Design API

### ResponsiveHelper

Multi-screen support with adaptive layouts.

```dart
// Get responsive values
final padding = context.responsivePadding;
final fontSize = context.responsiveFontSize(16);

// Responsive layouts
ResponsiveLayout(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)

// Responsive builders
ResponsiveBuilder(
  builder: (context, screenSize) {
    return screenSize == ScreenSize.mobile 
        ? MobileWidget() 
        : DesktopWidget();
  },
)
```

## Performance API

### PerformanceHelper

Optimization utilities for production performance.

```dart
// Track performance
PerformanceHelper.instance.startTracking('device_discovery');
// ... perform operation
PerformanceHelper.instance.stopTracking('device_discovery');

// Optimized image loading
PerformanceHelper.optimizedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  cacheKey: 'profile_image',
)

// Debounce function calls
PerformanceHelper.debounce('search', Duration(milliseconds: 300), () {
  performSearch(query);
});
```

## Error Handling Patterns

### Service Errors

```dart
try {
  await ServiceCoordinator.instance.initializeAll();
} catch (e) {
  await ErrorHandlerService.instance.reportError(
    e, 
    StackTrace.current,
    context: 'service_initialization',
  );
  
  // Show user-friendly error
  AppSnackBar.showError(context, 'Connection unavailable');
}
```

### UI Error Boundaries

```dart
Widget build(BuildContext context) {
  return asyncValue.when(
    data: (data) => DataWidget(data),
    loading: () => AppLoadingIndicator(
      message: 'Loading devices...',
      showMessage: true,
    ),
    error: (error, stack) => EmptyState(
      icon: Icons.error_outline,
      title: 'Connection Error',
      description: 'Unable to connect to nearby devices',
      actionText: 'Retry',
      onAction: () => retry(),
    ),
  );
}
```

## Testing API

### Integration Tests

```dart
// Widget testing with providers
testWidgets('SOS button activates emergency mode', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: SOSScreen(),
      ),
    ),
  );
  
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle();
  
  expect(find.text('SOS Active'), findsOneWidget);
});

// Service testing
test('ServiceCoordinator initializes all services', () async {
  final coordinator = ServiceCoordinator.instance;
  final result = await coordinator.initializeAll();
  
  expect(result, isTrue);
  expect(coordinator.getServiceStatus()['nearby'], isTrue);
});
```

## Production Deployment

### Build Configuration

```bash
# Clean build for production
flutter clean
flutter pub get

# Build APK for Android
flutter build apk --release --obfuscate --split-debug-info=./debug-symbols

# Build iOS
flutter build ios --release --obfuscate --split-debug-info=./debug-symbols
```

### Environment Configuration

```dart
// Production settings
const bool kProductionMode = bool.fromEnvironment('PRODUCTION', defaultValue: false);
const String kApiEndpoint = String.fromEnvironment('API_ENDPOINT', defaultValue: 'https://api.example.com');

// Feature flags
const bool kEnableCloudSync = bool.fromEnvironment('ENABLE_CLOUD_SYNC', defaultValue: true);
const bool kEnableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
```

---

**📱 Ready for Production Deployment | 🛡️ Comprehensive Error Handling | ♿ Fully Accessible | 📊 Performance Optimized**