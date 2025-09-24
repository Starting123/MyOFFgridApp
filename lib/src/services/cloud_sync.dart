import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../data/db.dart';
import '../utils/constants.dart';

class CloudSync {
  final AppDatabase db;
  final http.Client _client = http.Client();
  final String baseUrl;

  CloudSync(this.db, {this.baseUrl = Constants.cloudEndpoint});

  /// Push messages to cloud
  Future<void> pushMessages() async {
    try {
      // Get unsynced messages
      final messages = await (db.select(db.messages)
        ..where((m) => m.isSynced.equals(false))).get();

      for (final message in messages) {
        await _syncMessageToCloud(message);
      }
    } catch (e) {
      debugPrint('Error pushing messages: $e');
    }
  }

  /// Pull new messages from cloud
  Future<void> pullMessages() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/messages'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final messageData in data) {
          await _saveMessageFromCloud(messageData);
        }
      }
    } catch (e) {
      debugPrint('Error pulling messages: $e');
    }
  }

  Future<void> _syncMessageToCloud(Message message) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id': message.id,
          'content': message.content,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'isSos': message.isSos,
          'timestamp': message.timestamp.toIso8601String(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Mark as synced
        await db.updateMessageSyncStatus(message.id, true);
      }
    } catch (e) {
      debugPrint('Error syncing message ${message.id}: $e');
    }
  }

  Future<void> _saveMessageFromCloud(Map<String, dynamic> data) async {
    try {
      // Check if message already exists
      final existing = await (db.select(db.messages)
        ..where((m) => m.id.equals(data['id']))).getSingleOrNull();
      
      if (existing != null) return;

      await db.insertMessage(MessageCompanion.insert(
        content: data['content'],
        senderId: data['senderId'],
        receiverId: Value(data['receiverId']),
        isSos: Value(data['isSos'] ?? false),
        timestamp: DateTime.parse(data['timestamp']),
        isSynced: const Value(true),
      ));
    } catch (e) {
      debugPrint('Error saving message from cloud: $e');
    }
  }

  /// Start sync process
  Future<void> sync() async {
    await pushMessages();
    await pullMessages();
  }

  void dispose() {
    _client.close();
  }
}