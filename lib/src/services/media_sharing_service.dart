import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../models/chat_models.dart';
import '../services/enhanced_file_transfer_service.dart';
import '../services/local_database_service.dart';

class MediaSharingService {
  static final MediaSharingService _instance = MediaSharingService._internal();
  static MediaSharingService get instance => _instance;
  MediaSharingService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final EnhancedFileTransferService _fileTransfer = EnhancedFileTransferService.instance;
  final LocalDatabaseService _database = LocalDatabaseService();

  /// Pick and send image from camera
  Future<ChatMessage?> captureAndSendImage({
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processAndSendMedia(
        filePath: image.path,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        type: MessageType.image,
      );
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Pick and send image from gallery
  Future<ChatMessage?> pickAndSendImage({
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processAndSendMedia(
        filePath: image.path,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        type: MessageType.image,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick and send video
  Future<ChatMessage?> pickAndSendVideo({
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2), // Limit video size for P2P
      );

      if (video == null) return null;

      return await _processAndSendMedia(
        filePath: video.path,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        type: MessageType.video,
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Pick and send general file
  Future<ChatMessage?> pickAndSendFile({
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.single.path == null) return null;

      final file = result.files.single;
      
      // Check file size (limit to 10MB for P2P transfer)
      if (file.size > 10 * 1024 * 1024) {
        throw Exception('File too large (max 10MB for offline sharing)');
      }

      return await _processAndSendMedia(
        filePath: file.path!,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        type: MessageType.file,
        fileName: file.name,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
  }

  /// Process and send media file
  Future<ChatMessage?> _processAndSendMedia({
    required String filePath,
    required String senderId,
    required String senderName,
    required String receiverId,
    required MessageType type,
    String? fileName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Create message with pending status
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        content: fileName ?? _getFileNameFromPath(filePath),
        type: type,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        filePath: filePath,
        metadata: {
          'fileSize': await file.length(),
          'mimeType': lookupMimeType(filePath) ?? 'application/octet-stream',
          if (fileName != null) 'originalName': fileName,
        },
      );

      // Save to database first
      await _database.insertMessage(message);

      // Start file transfer in background
      _transferFileInBackground(message);

      return message;
    } catch (e) {
      debugPrint('Error processing media: $e');
      rethrow;
    }
  }

  /// Transfer file in background and update message status
  void _transferFileInBackground(ChatMessage message) async {
    try {
      // Update status to sending
      await _database.updateMessageStatus(message.id, MessageStatus.sending);

      // Transfer file via P2P based on type
      await _transferByType(message);
      await _database.updateMessageStatus(message.id, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error transferring file: $e');
      await _database.updateMessageStatus(message.id, MessageStatus.failed);
    }
  }

  /// Transfer file based on message type
  Future<void> _transferByType(ChatMessage message) async {
    switch (message.type) {
      case MessageType.image:
        await _fileTransfer.sendImageFile(message.filePath!, receiverId: message.receiverId);
        break;
      case MessageType.video:
        await _fileTransfer.sendVideoFile(message.filePath!, receiverId: message.receiverId);
        break;
      case MessageType.file:
        await _fileTransfer.sendDocumentFile(message.filePath!, receiverId: message.receiverId);
        break;
      default:
        throw Exception('Unsupported file type: ${message.type}');
    }
  }

  /// Get file name from path
  String _getFileNameFromPath(String path) {
    return path.split('/').last.split('\\').last;
  }

  /// Get thumbnail for image/video messages
  Future<Uint8List?> getThumbnail(String filePath, MessageType type) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      if (type == MessageType.image) {
        // For images, read directly (could add thumbnail generation)
        return await file.readAsBytes();
      } else if (type == MessageType.video) {
        // For videos, you'd use a video thumbnail package
        // For now, return null and show video icon
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting thumbnail: $e');
      return null;
    }
  }

  /// Check if file still exists locally
  Future<bool> isFileAvailable(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }
}