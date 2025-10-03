import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = 'OffGridSOS';
  
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 500, // Debug level
      );
    }
  }
  
  static void info(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // Info level
    );
  }
  
  static void warning(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // Warning level
    );
  }
  
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void success(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 850, // Success level (between info and warning)
    );
  }
  
  static void critical(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1200, // Critical level (highest)
    );
  }
  
  // Convenience methods for different components
  static void encryption(String message) => debug(message, 'Encryption');
  static void sos(String message) => debug(message, 'SOS');
  static void chat(String message) => debug(message, 'Chat');
  static void nearby(String message) => debug(message, 'Nearby');
  static void p2p(String message) => debug(message, 'P2P');
  static void mesh(String message) => debug(message, 'Mesh');
}