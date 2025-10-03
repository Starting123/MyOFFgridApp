import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Global logger instance for the application
/// Provides structured logging with appropriate levels and formatting
class AppLogger {
  static Logger? _instance;
  
  /// Get the logger instance
  static Logger get instance {
    _instance ??= Logger(
      printer: kDebugMode 
        ? PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            printTime: true,
          )
        : SimplePrinter(),
      level: kDebugMode ? Level.debug : Level.info,
    );
    return _instance!;
  }
  
  /// Log verbose messages (lowest priority)
  static void v(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.v(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log debug messages
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log info messages
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning messages
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log error messages (highest priority)
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log fatal/wtf messages
  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }
}