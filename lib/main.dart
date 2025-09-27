/// Off-Grid SOS & Nearby Share - Main Application Entry Point
/// 
/// This is the production-ready Flutter application for emergency communication
/// and nearby sharing in offline environments.
/// 
/// Architecture: Clean Architecture with separation of concerns
/// State Management: Riverpod 3.0 with async providers
/// UI Framework: Flutter with Material 3 design system
/// 
/// Key Features:
/// - Multi-protocol P2P communication (Nearby/BLE/WiFi Direct)
/// - Emergency SOS broadcasting and rescue coordination
/// - Offline-first messaging with cloud synchronization
/// - Real-time device discovery and status monitoring
/// - Comprehensive error handling and recovery
/// - Accessibility and responsive design support
/// 
/// Production Status: ✅ Ready for deployment
/// 
/// @author Flutter Development Team
/// @version 1.0.0
/// @since 2024
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/main_app.dart';
import 'src/services/service_coordinator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services before app startup
  try {
    await ServiceCoordinator.instance.initializeAll();
    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Service initialization warning: $e');
    // App can still run with limited functionality
  }

  // Run the application with Riverpod state management
  runApp(
    const ProviderScope(
      child: OffGridApp(),
    ),
  );
}