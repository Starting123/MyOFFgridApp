import 'package:flutter/material.dart';

enum UserRole {
  sosUser,
  rescueUser,
  relayUser,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.sosUser:
        return 'SOS User';
      case UserRole.rescueUser:
        return 'Rescue User';
      case UserRole.relayUser:
        return 'Relay User';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.sosUser:
        return Colors.red;
      case UserRole.rescueUser:
        return Colors.blue;
      case UserRole.relayUser:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.sosUser:
        return Icons.warning;
      case UserRole.rescueUser:
        return Icons.shield;
      case UserRole.relayUser:
        return Icons.wifi;
    }
  }

  String get description {
    switch (this) {
      case UserRole.sosUser:
        return 'Can send emergency SOS signals when in distress (RED mode)';
      case UserRole.rescueUser:
        return 'Can respond to SOS calls and help rescue people (BLUE mode)';
      case UserRole.relayUser:
        return 'Helps relay messages to extend network range (GREEN mode)';
    }
  }
}