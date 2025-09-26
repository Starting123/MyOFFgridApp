import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize services here when ready
  // final serviceManager = OffGridServiceManager();
  // await serviceManager.initializeAllServices();
  
  runApp(
    ProviderScope(
      child: const OffGridApp(),
    ),
  );
}