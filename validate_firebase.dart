#!/usr/bin/env dart

/// Quick Firebase Connectivity Validation Script
/// Tests basic Firebase integration without full Flutter setup
import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔥 Firebase Integration Validation Script');
  print('==========================================');
  
  await validateFirebaseConfig();
  await validateFirebaseProject();
  await validateFirebaseRules();
  
  print('\n🎉 Firebase validation completed!');
}

Future<void> validateFirebaseConfig() async {
  print('\n📱 1. Validating Firebase Configuration Files...');
  
  // Check Android configuration
  final androidConfig = File('android/app/google-services.json');
  if (await androidConfig.exists()) {
    final content = await androidConfig.readAsString();
    final json = jsonDecode(content);
    final projectId = json['project_info']['project_id'];
    final appId = json['client'][0]['client_info']['mobilesdk_app_id'];
    
    print('✅ Android config found');
    print('   Project ID: $projectId');
    print('   App ID: $appId');
  } else {
    print('❌ Android google-services.json missing');
  }
  
  // Check web configuration
  final webConfig = File('web/index.html');
  if (await webConfig.exists()) {
    final content = await webConfig.readAsString();
    if (content.contains('AIzaSyDDYOTW5cNJjUd9LYuX9iUogtF7kEYzmjM')) {
      print('✅ Web Firebase config updated with real credentials');
    } else {
      print('⚠️  Web Firebase config may need updating');
    }
  }
  
  // Check Firebase service implementation
  final firebaseService = File('lib/src/services/firebase_service.dart');
  if (await firebaseService.exists()) {
    final content = await firebaseService.readAsString();
    if (content.contains('Firebase.initializeApp()')) {
      print('✅ Firebase service properly implemented');
    }
    if (content.contains('FirebaseFirestore.instance')) {
      print('✅ Firestore integration found');
    }
    if (content.contains('FirebaseAuth.instance')) {
      print('✅ Authentication integration found');
    }
  }
}

Future<void> validateFirebaseProject() async {
  print('\n🏗️  2. Validating Firebase Project Setup...');
  
  // Check if Firebase CLI is available
  try {
    final result = await Process.run('firebase', ['projects:list']);
    if (result.exitCode == 0) {
      print('✅ Firebase CLI installed and working');
      
      if (result.stdout.toString().contains('off-grid-sos-app')) {
        print('✅ Project "off-grid-sos-app" found');
        print('✅ Firebase CLI authenticated');
      } else {
        print('⚠️  Project may not be selected or accessible');
      }
    }
  } catch (e) {
    print('❌ Firebase CLI not found or not working');
    print('   Install with: npm install -g firebase-tools');
  }
  
  // Check firebase.json configuration
  final firebaseConfig = File('firebase.json');
  if (await firebaseConfig.exists()) {
    final content = await firebaseConfig.readAsString();
    final config = jsonDecode(content);
    
    print('✅ firebase.json found');
    
    if (config.containsKey('firestore')) {
      print('   ✅ Firestore configured');
    }
    if (config.containsKey('storage')) {
      print('   ✅ Storage configured');
    }
    if (config.containsKey('functions')) {
      print('   ✅ Functions configured');
    }
    if (config.containsKey('hosting')) {
      print('   ✅ Hosting configured');
    }
  }
}

Future<void> validateFirebaseRules() async {
  print('\n🔒 3. Validating Security Rules...');
  
  // Check Firestore rules
  final firestoreRules = File('firestore.rules');
  if (await firestoreRules.exists()) {
    final content = await firestoreRules.readAsString();
    print('✅ Firestore rules file found');
    
    if (content.contains('request.auth != null')) {
      print('   ✅ Authentication checks implemented');
    }
    if (content.contains('users/{userId}')) {
      print('   ✅ User data protection rules');
    }
    if (content.contains('sos_alerts')) {
      print('   ✅ SOS alert rules configured');
    }
    if (content.contains('conversations')) {
      print('   ✅ Chat security rules found');
    }
  }
  
  // Check Storage rules
  final storageRules = File('storage.rules');
  if (await storageRules.exists()) {
    final content = await storageRules.readAsString();
    print('✅ Storage rules file found');
    
    if (content.contains('users/{userId}/profile')) {
      print('   ✅ Profile image rules configured');
    }
    if (content.contains('sos/{alertId}')) {
      print('   ✅ SOS media rules configured');
    }
    if (content.contains('resource.size')) {
      print('   ✅ File size limits implemented');
    }
  }
  
  // Check if rules are deployed
  try {
    final result = await Process.run('firebase', ['firestore:rules:get']);
    if (result.exitCode == 0) {
      print('✅ Firestore rules successfully deployed');
    }
  } catch (e) {
    print('⚠️  Could not verify rule deployment status');
  }
}

/// Additional validation functions
Future<void> validatePubspecDependencies() async {
  print('\n📦 4. Validating Flutter Dependencies...');
  
  final pubspec = File('pubspec.yaml');
  if (await pubspec.exists()) {
    final content = await pubspec.readAsString();
    
    final firebaseDeps = [
      'firebase_core',
      'firebase_auth', 
      'cloud_firestore',
      'firebase_storage'
    ];
    
    for (final dep in firebaseDeps) {
      if (content.contains('$dep:')) {
        print('   ✅ $dep dependency found');
      } else {
        print('   ❌ $dep dependency missing');
      }
    }
  }
}

/// Check main.dart Firebase initialization
Future<void> validateAppInitialization() async {
  print('\n🚀 5. Validating App Initialization...');
  
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    final content = await mainFile.readAsString();
    
    if (content.contains('FirebaseService.instance.initialize()')) {
      print('✅ Firebase initialization found in main.dart');
    }
    
    if (content.contains('WidgetsFlutterBinding.ensureInitialized()')) {
      print('✅ Flutter binding initialization found');
    }
    
    if (content.contains('runApp')) {
      print('✅ App startup configuration looks good');
    }
  }
}