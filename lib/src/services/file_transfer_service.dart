import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

/// Service for handling file transfers between devices
class FileTransferService {
  static final FileTransferService _instance = FileTransferService._internal();
  static FileTransferService get instance => _instance;
  FileTransferService._internal();

  static const int maxFileSize = 50 * 1024 * 1024; // 50MB max file size
  static const int chunkSize = 64 * 1024; // 64KB chunks for transfer
  
  final Map<String, FileTransferProgress> _activeTransfers = {};
  final Map<String, Completer<File?>> _transferCompleters = {};

  /// Prepare file for transfer by creating metadata and chunks
  Future<FileTransferInfo?> prepareFileForTransfer(File file) async {
    try {
      if (!await file.exists()) {
        debugPrint('File does not exist: ${file.path}');
        return null;
      }

      int fileSize = await file.length();
      if (fileSize > maxFileSize) {
        debugPrint('File too large: $fileSize bytes (max: $maxFileSize)');
        return null;
      }

      String fileName = path.basename(file.path);
      String? mimeType = lookupMimeType(file.path);
      String fileId = DateTime.now().millisecondsSinceEpoch.toString();

      // Calculate number of chunks
      int totalChunks = (fileSize / chunkSize).ceil();

      return FileTransferInfo(
        fileId: fileId,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType ?? 'application/octet-stream',
        totalChunks: totalChunks,
        chunkSize: chunkSize,
        filePath: file.path,
      );
    } catch (e) {
      debugPrint('Error preparing file for transfer: $e');
      return null;
    }
  }

  /// Get file chunk by index
  Future<FileChunk?> getFileChunk(String filePath, int chunkIndex) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      RandomAccessFile raf = await file.open();
      int fileSize = await raf.length();
      int startByte = chunkIndex * chunkSize;
      int endByte = (startByte + chunkSize).clamp(0, fileSize);
      int actualChunkSize = endByte - startByte;

      if (startByte >= fileSize) {
        await raf.close();
        return null;
      }

      await raf.setPosition(startByte);
      Uint8List data = await raf.read(actualChunkSize);
      await raf.close();

      return FileChunk(
        chunkIndex: chunkIndex,
        data: data,
        size: actualChunkSize,
      );
    } catch (e) {
      debugPrint('Error reading file chunk: $e');
      return null;
    }
  }

  /// Start file transfer (sender side)
  Future<String?> startFileTransfer(String filePath, String peerId, Function(FileTransferProgress) onProgress) async {
    try {
      File file = File(filePath);
      FileTransferInfo? transferInfo = await prepareFileForTransfer(file);
      
      if (transferInfo == null) {
        return null;
      }

      // Initialize transfer progress
      FileTransferProgress progress = FileTransferProgress(
        transferId: transferInfo.fileId,
        fileName: transferInfo.fileName,
        totalSize: transferInfo.fileSize,
        transferredSize: 0,
        totalChunks: transferInfo.totalChunks,
        transferredChunks: 0,
        isComplete: false,
        isSending: true,
      );

      _activeTransfers[transferInfo.fileId] = progress;

      // Send transfer initiation message
      // Map<String, dynamic> initMessage = {
      //   'type': 'file_transfer_init',
      //   'transferId': transferInfo.fileId,
      //   'fileName': transferInfo.fileName,
      //   'fileSize': transferInfo.fileSize,
      //   'mimeType': transferInfo.mimeType,
      //   'totalChunks': transferInfo.totalChunks,
      //   'chunkSize': transferInfo.chunkSize,
      // };

      // Here you would send this through your P2P service
      // await p2pService.sendMessage(peerId, jsonEncode(initMessage));

      debugPrint('File transfer initiated: ${transferInfo.fileName} (${transferInfo.fileSize} bytes)');
      onProgress(progress);

      return transferInfo.fileId;
    } catch (e) {
      debugPrint('Error starting file transfer: $e');
      return null;
    }
  }

  /// Handle incoming file transfer chunk
  Future<void> handleFileChunk(String transferId, int chunkIndex, Uint8List data) async {
    try {
      FileTransferProgress? progress = _activeTransfers[transferId];
      if (progress == null) {
        debugPrint('No active transfer found for ID: $transferId');
        return;
      }

      // Create temp file path
      Directory tempDir = await getTemporaryDirectory();
      String tempFilePath = path.join(tempDir.path, 'transfer_${transferId}_${progress.fileName}');
      
      // Write chunk to file
      File tempFile = File(tempFilePath);
      RandomAccessFile raf = await tempFile.open(mode: FileMode.writeOnlyAppend);
      
      int expectedPosition = chunkIndex * chunkSize;
      await raf.setPosition(expectedPosition);
      await raf.writeFrom(data);
      await raf.close();

      // Update progress
      progress.transferredChunks++;
      progress.transferredSize += data.length;
      progress.isComplete = progress.transferredChunks >= progress.totalChunks;

      if (progress.isComplete) {
        // Move file to final location
        Directory appDir = await getApplicationDocumentsDirectory();
        String finalPath = path.join(appDir.path, 'received', progress.fileName);
        
        Directory receivedDir = Directory(path.dirname(finalPath));
        if (!await receivedDir.exists()) {
          await receivedDir.create(recursive: true);
        }

        await tempFile.copy(finalPath);
        await tempFile.delete();

        progress.finalPath = finalPath;
        
        Completer<File?>? completer = _transferCompleters[transferId];
        completer?.complete(File(finalPath));
        
        debugPrint('File transfer completed: ${progress.fileName}');
      }

    } catch (e) {
      debugPrint('Error handling file chunk: $e');
      Completer<File?>? completer = _transferCompleters[transferId];
      completer?.complete(null);
    }
  }

  /// Accept incoming file transfer
  Future<File?> acceptFileTransfer(String transferId) async {
    try {
      FileTransferProgress? progress = _activeTransfers[transferId];
      if (progress == null) {
        return null;
      }

      Completer<File?> completer = Completer<File?>();
      _transferCompleters[transferId] = completer;

      // Send acceptance message
      // Map<String, dynamic> acceptMessage = {
      //   'type': 'file_transfer_accept',
      //   'transferId': transferId,
      // };

      // Here you would send this through your P2P service
      // await p2pService.sendMessage(senderId, jsonEncode(acceptMessage));

      return completer.future;
    } catch (e) {
      debugPrint('Error accepting file transfer: $e');
      return null;
    }
  }

  /// Reject incoming file transfer
  Future<void> rejectFileTransfer(String transferId) async {
    try {
      _activeTransfers.remove(transferId);
      _transferCompleters.remove(transferId);

      // Send rejection message
      // Map<String, dynamic> rejectMessage = {
      //   'type': 'file_transfer_reject',
      //   'transferId': transferId,
      // };

      // Here you would send this through your P2P service
      // await p2pService.sendMessage(senderId, jsonEncode(rejectMessage));

      debugPrint('File transfer rejected: $transferId');
    } catch (e) {
      debugPrint('Error rejecting file transfer: $e');
    }
  }

  /// Cancel ongoing file transfer
  Future<void> cancelFileTransfer(String transferId) async {
    try {
      _activeTransfers.remove(transferId);
      Completer<File?>? completer = _transferCompleters.remove(transferId);
      completer?.complete(null);

      // Send cancellation message
      // Map<String, dynamic> cancelMessage = {
      //   'type': 'file_transfer_cancel',
      //   'transferId': transferId,
      // };

      // Here you would send this through your P2P service
      // await p2pService.sendMessage(peerId, jsonEncode(cancelMessage));

      debugPrint('File transfer cancelled: $transferId');
    } catch (e) {
      debugPrint('Error cancelling file transfer: $e');
    }
  }

  /// Get transfer progress
  FileTransferProgress? getTransferProgress(String transferId) {
    return _activeTransfers[transferId];
  }

  /// Get all active transfers
  List<FileTransferProgress> getActiveTransfers() {
    return _activeTransfers.values.toList();
  }

  /// Get file type from mime type
  FileType getFileType(String mimeType) {
    if (mimeType.startsWith('image/')) return FileType.image;
    if (mimeType.startsWith('video/')) return FileType.video;
    if (mimeType.startsWith('audio/')) return FileType.audio;
    if (mimeType.startsWith('text/')) return FileType.document;
    if (mimeType.contains('pdf')) return FileType.document;
    return FileType.other;
  }

  /// Get human readable file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clean up completed transfers
  void cleanupTransfers() {
    _activeTransfers.removeWhere((key, value) => value.isComplete);
  }
}

/// File transfer information
class FileTransferInfo {
  final String fileId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final int totalChunks;
  final int chunkSize;
  final String filePath;

  FileTransferInfo({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.totalChunks,
    required this.chunkSize,
    required this.filePath,
  });
}

/// File chunk data
class FileChunk {
  final int chunkIndex;
  final Uint8List data;
  final int size;

  FileChunk({
    required this.chunkIndex,
    required this.data,
    required this.size,
  });
}

/// File transfer progress
class FileTransferProgress {
  final String transferId;
  final String fileName;
  final int totalSize;
  int transferredSize;
  final int totalChunks;
  int transferredChunks;
  bool isComplete;
  final bool isSending;
  String? finalPath;
  DateTime startTime;

  FileTransferProgress({
    required this.transferId,
    required this.fileName,
    required this.totalSize,
    required this.transferredSize,
    required this.totalChunks,
    required this.transferredChunks,
    required this.isComplete,
    required this.isSending,
    this.finalPath,
  }) : startTime = DateTime.now();

  double get progress => totalChunks > 0 ? transferredChunks / totalChunks : 0.0;
  
  String get progressText => '$transferredChunks/$totalChunks chunks (${FileTransferService.instance.formatFileSize(transferredSize)}/${FileTransferService.instance.formatFileSize(totalSize)})';
}

/// File types
enum FileType {
  image,
  video,
  audio,
  document,
  other,
}