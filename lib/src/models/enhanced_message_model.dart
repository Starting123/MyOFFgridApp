// This file provides compatibility for services that depend on enhanced message model
// But we'll use the standard ChatMessage from chat_models.dart instead

import 'chat_models.dart';

export 'chat_models.dart' show ChatMessage, MessageType, MessageStatus;

// Alias for backward compatibility
typedef EnhancedMessageModel = ChatMessage;

// SOSBroadcast model for SOS functionality
class SOSBroadcast {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final String urgencyLevel;

  SOSBroadcast({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.urgencyLevel = 'high',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'urgencyLevel': urgencyLevel,
    };
  }

  factory SOSBroadcast.fromJson(Map<String, dynamic> json) {
    return SOSBroadcast(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      message: json['message'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      urgencyLevel: json['urgencyLevel'] ?? 'high',
    );
  }
}