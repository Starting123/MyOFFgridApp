import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../services/nearby_service.dart';
import '../services/enhanced_message_queue_service.dart';
import '../models/enhanced_message_model.dart';

/// Enhanced File Transfer Service for sharing images, videos, and documents
class EnhancedFileTransferService {
  static final EnhancedFileTransferService _instance = EnhancedFileTransferService._internal();
  static EnhancedFileTransferService get instance => _instance;
  
  final NearbyService _nearbyService = NearbyService.instance;
  final MessageQueueService _messageQueue = MessageQueueService.instance;


  // Maximum file size (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
  
  // Chunk size for file transfer (64KB)
  static const int chunkSize = 64 * 1024;

  EnhancedFileTransferService._internal();

  /// Send image file
  Future<void> sendImageFile(String filePath, {String? receiverId}) async {
    await _sendFile(filePath, MessageType.image, receiverId: receiverId);
  }

  /// Send video file
  Future<void> sendVideoFile(String filePath, {String? receiverId}) async {
    await _sendFile(filePath, MessageType.video, receiverId: receiverId);
  }

  /// Send document file
  Future<void> sendDocumentFile(String filePath, {String? receiverId}) async {
    await _sendFile(filePath, MessageType.file, receiverId: receiverId);
  }

  /// Generic file sending method
  Future<void> _sendFile(String filePath, MessageType type, {String? receiverId}) async {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File too large: ${_formatFileSize(fileSize)} (max: ${_formatFileSize(maxFileSize)})');
      }

      // Get file info
      final fileName = path.basename(filePath);
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      
      print('📎 Preparing to send file: $fileName ($mimeType, ${_formatFileSize(fileSize)})');

      // Create message record first
      final message = EnhancedMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        receiverId: receiverId,
        content: 'Shared file: $fileName',
        timestamp: DateTime.now(),
        type: type,
        status: MessageStatus.pending,
        filePath: filePath,
      );

      // Save to database
      await _messageQueue.insertPendingMessage(message);

      // Read file content
      final fileBytes = await file.readAsBytes();
      
      // Create file transfer payload
      final filePayload = {
        'type': 'file_transfer',
        'messageId': message.id,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'messageType': type.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send file metadata first
      await _nearbyService.sendMessage(jsonEncode(filePayload), type: 'file_metadata');

      // Send file in chunks
      await _sendFileInChunks(message.id, fileBytes);

      // Mark as sent
      await _messageQueue.markMessageSent(int.parse(message.id));
      
      print('✅ File sent successfully: $fileName');

    } catch (e) {
      print('❌ Error sending file: $e');
      rethrow;
    }
  }

  /// Send file content in chunks
  Future<void> _sendFileInChunks(String messageId, Uint8List fileBytes) async {
    final totalChunks = (fileBytes.length / chunkSize).ceil();
    
    print('📦 Sending file in $totalChunks chunks...');

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize < fileBytes.length) ? start + chunkSize : fileBytes.length;
      final chunk = fileBytes.sublist(start, end);
      
      final chunkPayload = {
        'type': 'file_chunk',
        'messageId': messageId,
        'chunkIndex': i,
        'totalChunks': totalChunks,
        'chunkData': base64Encode(chunk),
        'chunkSize': chunk.length,
      };

      await _nearbyService.sendMessage(jsonEncode(chunkPayload), type: 'file_chunk');
      
      // Small delay between chunks to avoid overwhelming the connection
      await Future.delayed(const Duration(milliseconds: 50));
      
      if ((i + 1) % 10 == 0) {
        print('📦 Sent ${i + 1}/$totalChunks chunks');
      }
    }

    // Send completion signal
    final completionPayload = {
      'type': 'file_complete',
      'messageId': messageId,
      'totalChunks': totalChunks,
    };

    await _nearbyService.sendMessage(jsonEncode(completionPayload), type: 'file_complete');
    print('✅ File transfer completed');
  }

  /// Handle incoming file transfer
  void handleIncomingFileTransfer(Map<String, dynamic> payload) {
    final type = payload['type'] as String;
    
    switch (type) {
      case 'file_metadata':
        _handleFileMetadata(payload);
        break;
      case 'file_chunk':
        _handleFileChunk(payload);
        break;
      case 'file_complete':
        _handleFileComplete(payload);
        break;
    }
  }

  // File transfer state tracking
  final Map<String, FileTransferState> _activeTransfers = {};

  void _handleFileMetadata(Map<String, dynamic> payload) {
    final messageId = payload['messageId'] as String;
    final fileName = payload['fileName'] as String;
    final fileSize = payload['fileSize'] as int;
    final totalChunks = (fileSize / chunkSize).ceil();
    
    print('📥 Receiving file: $fileName (${_formatFileSize(fileSize)})');
    
    _activeTransfers[messageId] = FileTransferState(
      messageId: messageId,
      fileName: fileName,
      mimeType: payload['mimeType'] as String,
      fileSize: fileSize,
      totalChunks: totalChunks,
      receivedChunks: {},
    );
  }

  void _handleFileChunk(Map<String, dynamic> payload) {
    final messageId = payload['messageId'] as String;
    final chunkIndex = payload['chunkIndex'] as int;
    final chunkData = base64Decode(payload['chunkData'] as String);
    
    final transfer = _activeTransfers[messageId];
    if (transfer == null) {
      print('❌ Received chunk for unknown transfer: $messageId');
      return;
    }

    transfer.receivedChunks[chunkIndex] = chunkData;
    
    if ((chunkIndex + 1) % 10 == 0) {
      print('📥 Received ${transfer.receivedChunks.length}/${transfer.totalChunks} chunks');
    }
  }

  Future<void> _handleFileComplete(Map<String, dynamic> payload) async {
    final messageId = payload['messageId'] as String;
    final transfer = _activeTransfers[messageId];
    
    if (transfer == null) {
      print('❌ File completion for unknown transfer: $messageId');
      return;
    }

    try {
      // Verify all chunks received
      if (transfer.receivedChunks.length != transfer.totalChunks) {
        throw Exception('Missing chunks: received ${transfer.receivedChunks.length}/${transfer.totalChunks}');
      }

      // Reassemble file
      final fileBytes = _reassembleFile(transfer);
      
      // Save file to downloads directory
      final savedFilePath = await _saveReceivedFile(transfer.fileName, fileBytes);
      
      // Determine message type
      MessageType messageType = MessageType.file;
      if (transfer.mimeType.startsWith('image/')) {
        messageType = MessageType.image;
      } else if (transfer.mimeType.startsWith('video/')) {
        messageType = MessageType.video;
      }

      // Create message record
      final message = EnhancedMessageModel(
        id: messageId,
        senderId: 'peer',
        content: 'Received file: ${transfer.fileName}',
        timestamp: DateTime.now(),
        type: messageType,
        status: MessageStatus.delivered,
        filePath: savedFilePath,
      );

      // Save to database
      await _messageQueue.insertPendingMessage(message);
      
      print('✅ File received successfully: ${transfer.fileName} -> $savedFilePath');
      
      // Cleanup
      _activeTransfers.remove(messageId);
      
    } catch (e) {
      print('❌ Error handling file completion: $e');
      _activeTransfers.remove(messageId);
    }
  }

  /// Reassemble file from chunks
  Uint8List _reassembleFile(FileTransferState transfer) {
    final buffer = <int>[];
    
    // Sort chunks by index and combine
    for (int i = 0; i < transfer.totalChunks; i++) {
      final chunk = transfer.receivedChunks[i];
      if (chunk == null) {
        throw Exception('Missing chunk $i');
      }
      buffer.addAll(chunk);
    }
    
    return Uint8List.fromList(buffer);
  }

  /// Save received file to device storage
  Future<String> _saveReceivedFile(String fileName, Uint8List fileBytes) async {
    // Create downloads directory if it doesn't exist
    final downloadsDir = Directory('/storage/emulated/0/Download/OffGridSOS');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    // Generate unique filename if file already exists
    String filePath = path.join(downloadsDir.path, fileName);
    int counter = 1;
    
    while (await File(filePath).exists()) {
      final name = path.basenameWithoutExtension(fileName);
      final extension = path.extension(fileName);
      filePath = path.join(downloadsDir.path, '${name}_$counter$extension');
      counter++;
    }

    // Write file
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    
    return filePath;
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get supported file types
  static List<String> getSupportedImageTypes() {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  }

  static List<String> getSupportedVideoTypes() {
    return ['mp4', 'avi', 'mov', 'mkv'];
  }

  static List<String> getSupportedDocumentTypes() {
    return ['pdf', 'doc', 'docx', 'txt', 'zip'];
  }

  /// Check if file type is supported
  static bool isFileTypeSupported(String filePath) {
    final extension = path.extension(filePath).toLowerCase().substring(1);
    return getSupportedImageTypes().contains(extension) ||
           getSupportedVideoTypes().contains(extension) ||
           getSupportedDocumentTypes().contains(extension);
  }
}

/// File transfer state tracking
class FileTransferState {
  final String messageId;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final int totalChunks;
  final Map<int, Uint8List> receivedChunks;

  FileTransferState({
    required this.messageId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.totalChunks,
    required this.receivedChunks,
  });
}