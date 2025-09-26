import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/main_app.dart';
import 'src/services/offgrid_service_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  try {
    final serviceManager = OffGridServiceManager.instance;
    await serviceManager.initializeAllServices();
    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Service initialization failed: $e');
  }
  
  runApp(
    ProviderScope(
      child: const OffGridApp(),
    ),
  );
}