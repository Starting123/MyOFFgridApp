import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import '../models/chat_models.dart';
import 'local_database_service.dart';
import 'nearby_service.dart';
import 'p2p_service.dart';

class MultimediaChatService {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final NearbyService _nearbyService = NearbyService.instance;
  final P2PService _p2pService = P2PService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Stream controllers for real-time updates
  final ValueNotifier<List<ChatMessage>> messagesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  final ValueNotifier<List<NearbyDevice>> nearbyDevicesNotifier = ValueNotifier([]);

  String? _currentDeviceId;
  String? _currentDeviceName;

  Future<void> initialize() async {
    debugPrint('🔄 MultimediaChatService: กำลัง initialize...');
    
    // Get device info
    _currentDeviceId = await _getCurrentDeviceId();
    _currentDeviceName = await _getCurrentDeviceName();
    
    // Initialize services
    await _nearbyService.initialize();
    await _p2pService.initialize();
    
    // Set up listeners
    _setupServiceListeners();
    
    debugPrint('✅ MultimediaChatService: initialized สำเร็จ');
  }

  void _setupServiceListeners() {
    // Listen to nearby devices
    _nearbyService.onDeviceFound.listen((device) {
      debugPrint('📱 Nearby device found: $device');
    });

    _nearbyService.onDeviceLost.listen((deviceId) {
      debugPrint('📶 Device lost: $deviceId');
    });

    // Listen to incoming messages
    _nearbyService.onMessage.listen((messageData) {
      try {
        // Parse the incoming data into a ChatMessage
        final message = _parseIncomingMessage(messageData);
        if (message != null) {
          _handleIncomingMessage(message);
        }
      } catch (e) {
        debugPrint('❌ Error parsing nearby message: $e');
      }
    });

    _p2pService.onDataReceived.listen((messageData) {
      try {
        // Parse the incoming data into a ChatMessage
        final message = _parseIncomingMessage(messageData);
        if (message != null) {
          _handleIncomingMessage(message);
        }
      } catch (e) {
        debugPrint('❌ Error parsing P2P message: $e');
      }
    });
  }

  // Send text message
  Future<void> sendTextMessage(String receiverId, String content, {bool isEmergency = false}) async {
    final message = ChatMessage(
      id: _generateMessageId(),
      senderId: _currentDeviceId!,
      senderName: _currentDeviceName!,
      receiverId: receiverId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      isEmergency: isEmergency,
    );

    // Save to local database
    await _dbService.insertMessage(message);
    _updateMessagesNotifier();

    // Send via available channels
    await _sendMessageViaChannels(message);
  }

  // Send image message
  Future<void> sendImageMessage(String receiverId, {bool fromCamera = false, bool isEmergency = false}) async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (imageFile == null) return;

      // Save image to app directory
      final savedImagePath = await _saveMediaFile(imageFile.path, 'images');
      
      final message = ChatMessage(
        id: _generateMessageId(),
        senderId: _currentDeviceId!,
        senderName: _currentDeviceName!,
        receiverId: receiverId,
        content: 'Image: ${path.basename(savedImagePath)}',
        type: MessageType.image,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        filePath: savedImagePath,
        isEmergency: isEmergency,
        metadata: {
          'originalPath': imageFile.path,
          'fileSize': await File(imageFile.path).length(),
          'mimeType': 'image/jpeg',
        },
      );

      await _dbService.insertMessage(message);
      _updateMessagesNotifier();

      await _sendMessageViaChannels(message);
      
    } catch (e) {
      debugPrint('❌ Error sending image: $e');
    }
  }

  // Send video message
  Future<void> sendVideoMessage(String receiverId, {bool fromCamera = false, bool isEmergency = false}) async {
    try {
      final XFile? videoFile = await _imagePicker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (videoFile == null) return;

      final savedVideoPath = await _saveMediaFile(videoFile.path, 'videos');
      
      final message = ChatMessage(
        id: _generateMessageId(),
        senderId: _currentDeviceId!,
        senderName: _currentDeviceName!,
        receiverId: receiverId,
        content: 'Video: ${path.basename(savedVideoPath)}',
        type: MessageType.video,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        filePath: savedVideoPath,
        isEmergency: isEmergency,
        metadata: {
          'originalPath': videoFile.path,
          'fileSize': await File(videoFile.path).length(),
          'mimeType': 'video/mp4',
          'duration': 0, // Could be calculated
        },
      );

      await _dbService.insertMessage(message);
      _updateMessagesNotifier();

      await _sendMessageViaChannels(message);
      
    } catch (e) {
      debugPrint('❌ Error sending video: $e');
    }
  }

  // Send file message
  Future<void> sendFileMessage(String receiverId, {bool isEmergency = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final fileSize = result.files.single.size;

      final savedFilePath = await _saveMediaFile(filePath, 'files');
      
      final message = ChatMessage(
        id: _generateMessageId(),
        senderId: _currentDeviceId!,
        senderName: _currentDeviceName!,
        receiverId: receiverId,
        content: 'File: $fileName',
        type: MessageType.file,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        filePath: savedFilePath,
        isEmergency: isEmergency,
        metadata: {
          'originalPath': filePath,
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': _getMimeType(fileName),
        },
      );

      await _dbService.insertMessage(message);
      _updateMessagesNotifier();

      await _sendMessageViaChannels(message);
      
    } catch (e) {
      debugPrint('❌ Error sending file: $e');
    }
  }

  // Send location message
  Future<void> sendLocationMessage(String receiverId, {bool isEmergency = false}) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final message = ChatMessage(
        id: _generateMessageId(),
        senderId: _currentDeviceId!,
        senderName: _currentDeviceName!,
        receiverId: receiverId,
        content: 'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        type: MessageType.location,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        isEmergency: isEmergency,
        metadata: {
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
        },
      );

      await _dbService.insertMessage(message);
      _updateMessagesNotifier();

      await _sendMessageViaChannels(message);
      
    } catch (e) {
      debugPrint('❌ Error sending location: $e');
    }
  }

  // Send SOS message
  Future<void> sendSOSMessage(String receiverId) async {
    try {
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('! Could not get location for SOS: $e');
      }

      final sosContent = position != null 
          ? 'SOS EMERGENCY! Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
          : 'SOS EMERGENCY! Location unavailable';

      final message = ChatMessage(
        id: _generateMessageId(),
        senderId: _currentDeviceId!,
        senderName: _currentDeviceName!,
        receiverId: receiverId,
        content: sosContent,
        type: MessageType.sos,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        isEmergency: true,
        metadata: {
          'sosType': 'manual',
          'deviceRole': 'sosUser',
          'accuracy': position?.accuracy,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await _dbService.insertMessage(message);
      _updateMessagesNotifier();

      await _sendMessageViaChannels(message);
      
      // Broadcast SOS to all nearby devices
      await _broadcastSOSToAllDevices(message);
      
    } catch (e) {
      debugPrint('❌ Error sending SOS: $e');
    }
  }

  // Get messages for conversation
  Future<List<ChatMessage>> getMessagesForConversation(String participantId) async {
    return await _dbService.getMessagesForConversation(participantId);
  }

  // Load messages for UI
  Future<void> loadMessages(String participantId) async {
    final messages = await getMessagesForConversation(participantId);
    messagesNotifier.value = messages;
  }

  // Private helper methods
  Future<void> _sendMessageViaChannels(ChatMessage message) async {
    bool sent = false;

    // Try Nearby Connections first
    try {
      final messageJson = jsonEncode({
        'id': message.id,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'receiverId': message.receiverId,
        'content': message.content,
        'type': message.type.toString(),
        'status': message.status.toString(),
        'timestamp': message.timestamp.toIso8601String(),
        'isEmergency': message.isEmergency,
        'filePath': message.filePath,
      });
      await _nearbyService.sendMessage(messageJson, type: 'chat');
      await _updateMessageStatus(message.id, MessageStatus.sent);
      sent = true;
      debugPrint('✅ Message sent via Nearby Connections');
    } catch (e) {
      debugPrint('! Nearby Connections send failed: $e');
    }

    // Try P2P service as fallback
    if (!sent) {
      try {
        final messageJson = jsonEncode({
          'id': message.id,
          'senderId': message.senderId,
          'senderName': message.senderName,
          'receiverId': message.receiverId,
          'content': message.content,
          'type': message.type.toString(),
          'status': message.status.toString(),
          'timestamp': message.timestamp.toIso8601String(),
          'isEmergency': message.isEmergency,
          'filePath': message.filePath,
        });
        await _p2pService.sendMessage(messageJson, targetPeerId: message.receiverId);
        await _updateMessageStatus(message.id, MessageStatus.sent);
        sent = true;
        debugPrint('✅ Message sent via P2P Service');
      } catch (e) {
        debugPrint('! P2P Service send failed: $e');
      }
    }

    if (!sent) {
      await _updateMessageStatus(message.id, MessageStatus.failed);
      debugPrint('❌ Message failed to send via all channels');
    }
  }

  Future<void> _broadcastSOSToAllDevices(ChatMessage sosMessage) async {
    final nearbyDevices = nearbyDevicesNotifier.value;
    
    for (final device in nearbyDevices) {
      if (device.id != _currentDeviceId) {
        try {
          final broadcastMessage = sosMessage.copyWith(
            id: _generateMessageId(),
            receiverId: device.id,
          );
          
          await _sendMessageViaChannels(broadcastMessage);
          debugPrint('📡 SOS broadcast to ${device.name}');
        } catch (e) {
          debugPrint('! SOS broadcast failed to ${device.name}: $e');
        }
      }
    }
  }

  ChatMessage? _parseIncomingMessage(Map<String, dynamic> messageData) {
    try {
      // Check if this is a raw message or already structured
      if (messageData.containsKey('type') && messageData['type'] == 'chat') {
        // This is a simple text message from nearby service
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: messageData['senderId'] ?? 'unknown',
          senderName: messageData['senderName'] ?? 'Unknown',
          receiverId: _currentDeviceId ?? '',
          content: messageData['message'] ?? '',
          type: MessageType.text,
          status: MessageStatus.delivered,
          timestamp: DateTime.tryParse(messageData['timestamp'] ?? '') ?? DateTime.now(),
          isEmergency: messageData['isEmergency'] ?? false,
        );
      } else if (messageData.containsKey('id')) {
        // This is already a structured ChatMessage
        return ChatMessage(
          id: messageData['id'],
          senderId: messageData['senderId'],
          senderName: messageData['senderName'],
          receiverId: messageData['receiverId'],
          content: messageData['content'],
          type: MessageType.values.firstWhere(
            (e) => e.toString() == messageData['type'],
            orElse: () => MessageType.text,
          ),
          status: MessageStatus.values.firstWhere(
            (e) => e.toString() == messageData['status'],
            orElse: () => MessageStatus.delivered,
          ),
          timestamp: DateTime.tryParse(messageData['timestamp']) ?? DateTime.now(),
          isEmergency: messageData['isEmergency'] ?? false,
          filePath: messageData['filePath'],
        );
      }
    } catch (e) {
      debugPrint('❌ Error parsing message: $e');
    }
    return null;
  }

  Future<void> _handleIncomingMessage(ChatMessage message) async {
    // Save to database
    await _dbService.insertMessage(message);
    
    // Update UI if this conversation is active
    if (messagesNotifier.value.isNotEmpty) {
      final currentConversation = messagesNotifier.value.first.senderId == message.senderId ||
                                 messagesNotifier.value.first.receiverId == message.senderId;
      if (currentConversation) {
        _updateMessagesNotifier();
      }
    }

    // Handle special message types
    if (message.type == MessageType.sos) {
      _handleSOSMessage(message);
    }

    debugPrint('📨 Received ${message.type.name} message from ${message.senderName}');
  }

  void _handleSOSMessage(ChatMessage sosMessage) {
    // Show notification or alert for SOS message
    debugPrint('🆘 SOS MESSAGE RECEIVED from ${sosMessage.senderName}');
    debugPrint('   Content: ${sosMessage.content}');
    if (sosMessage.latitude != null && sosMessage.longitude != null) {
      debugPrint('   Location: ${sosMessage.latitude}, ${sosMessage.longitude}');
    }
  }

  Future<void> _updateMessagesNotifier() async {
    // This would be called when messages need to be refreshed
    // Implementation depends on current conversation context
  }

  Future<void> _updateMessageStatus(String messageId, MessageStatus status) async {
    await _dbService.updateMessageStatus(messageId, status);
    _updateMessagesNotifier();
  }

  Future<String> _saveMediaFile(String sourcePath, String category) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'media', category));
    await mediaDir.create(recursive: true);

    final fileName = path.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final destinationPath = path.join(mediaDir.path, newFileName);

    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  String _generateMessageId() {
    return 'msg_${_currentDeviceId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.doc':
      case '.docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _getCurrentDeviceId() async {
    // This should return a unique device identifier
    // For now, generate one based on device info
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _getCurrentDeviceName() async {
    // This should return the device name from settings
    // For now, return a default
    return 'My Device';
  }

  // Cleanup
  void dispose() {
    messagesNotifier.dispose();
    isConnectedNotifier.dispose();
    nearbyDevicesNotifier.dispose();
  }

  // Additional utility methods
  Future<bool> isMessageDelivered(String messageId) async {
    // Check if message was delivered
    // Implementation depends on your tracking mechanism
    return false;
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _updateMessageStatus(messageId, MessageStatus.read);
  }

  Future<void> retryFailedMessages() async {
    final pendingMessages = await _dbService.getPendingMessages();
    for (final message in pendingMessages) {
      await _sendMessageViaChannels(message);
    }
  }

  Future<List<ChatMessage>> getEmergencyMessages() async {
    return await _dbService.getEmergencyMessages();
  }
}