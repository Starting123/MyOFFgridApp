import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

/// Service for handling media messages including images, videos, and audio
class MediaMessageService {
  static final MediaMessageService _instance = MediaMessageService._internal();
  static MediaMessageService get instance => _instance;
  MediaMessageService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  
  /// Pick image from camera or gallery
  Future<MediaFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (xFile == null) return null;

      File file = File(xFile.path);
      String? mimeType = lookupMimeType(file.path);
      
      return MediaFile(
        file: file,
        type: MediaType.image,
        mimeType: mimeType ?? 'image/jpeg',
        size: await file.length(),
        name: path.basename(file.path),
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick video from camera or gallery
  Future<MediaFile?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? xFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
      );

      if (xFile == null) return null;

      File file = File(xFile.path);
      String? mimeType = lookupMimeType(file.path);
      
      return MediaFile(
        file: file,
        type: MediaType.video,
        mimeType: mimeType ?? 'video/mp4',
        size: await file.length(),
        name: path.basename(file.path),
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Pick multiple images
  Future<List<MediaFile>> pickMultipleImages() async {
    try {
      final List<XFile> xFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      List<MediaFile> mediaFiles = [];
      for (XFile xFile in xFiles) {
        File file = File(xFile.path);
        String? mimeType = lookupMimeType(file.path);
        
        mediaFiles.add(MediaFile(
          file: file,
          type: MediaType.image,
          mimeType: mimeType ?? 'image/jpeg',
          size: await file.length(),
          name: path.basename(file.path),
        ));
      }

      return mediaFiles;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Pick any file
  Future<MediaFile?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      PlatformFile platformFile = result.files.first;
      if (platformFile.path == null) return null;

      File file = File(platformFile.path!);
      String? mimeType = lookupMimeType(file.path) ?? platformFile.extension;
      
      return MediaFile(
        file: file,
        type: _getMediaTypeFromMime(mimeType ?? 'application/octet-stream'),
        mimeType: mimeType ?? 'application/octet-stream',
        size: platformFile.size,
        name: platformFile.name,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Pick audio file
  Future<MediaFile?> pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      PlatformFile platformFile = result.files.first;
      if (platformFile.path == null) return null;

      File file = File(platformFile.path!);
      String? mimeType = lookupMimeType(file.path);
      
      return MediaFile(
        file: file,
        type: MediaType.audio,
        mimeType: mimeType ?? 'audio/mpeg',
        size: platformFile.size,
        name: platformFile.name,
      );
    } catch (e) {
      debugPrint('Error picking audio: $e');
      return null;
    }
  }

  /// Save media file to app directory
  Future<String?> saveMediaFile(MediaFile mediaFile, {String? customName}) async {
    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String mediaDir = path.join(appDir.path, 'media', _getMediaFolder(mediaFile.type));
      
      Directory dir = Directory(mediaDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      String fileName = customName ?? '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}';
      String filePath = path.join(mediaDir, fileName);
      
      await mediaFile.file.copy(filePath);
      
      debugPrint('Media file saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving media file: $e');
      return null;
    }
  }

  /// Create thumbnail for image/video
  Future<Uint8List?> createThumbnail(MediaFile mediaFile, {int maxWidth = 200, int maxHeight = 200}) async {
    try {
      if (mediaFile.type == MediaType.image) {
        // For images, create a smaller version
        return await _createImageThumbnail(mediaFile.file, maxWidth, maxHeight);
      } else if (mediaFile.type == MediaType.video) {
        // For videos, extract first frame
        return await _createVideoThumbnail(mediaFile.file);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Compress image
  Future<MediaFile?> compressImage(MediaFile imageFile, {int quality = 85}) async {
    try {
      if (imageFile.type != MediaType.image) return null;

      // Use image_picker compression (basic implementation)
      final XFile? compressedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
      );

      if (compressedFile == null) return null;

      File file = File(compressedFile.path);
      String? mimeType = lookupMimeType(file.path);

      return MediaFile(
        file: file,
        type: MediaType.image,
        mimeType: mimeType ?? 'image/jpeg',
        size: await file.length(),
        name: 'compressed_${imageFile.name}',
      );
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Get media type from MIME type
  MediaType _getMediaTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) return MediaType.image;
    if (mimeType.startsWith('video/')) return MediaType.video;
    if (mimeType.startsWith('audio/')) return MediaType.audio;
    if (mimeType.startsWith('text/')) return MediaType.document;
    if (mimeType.contains('pdf')) return MediaType.document;
    return MediaType.file;
  }

  /// Get folder name for media type
  String _getMediaFolder(MediaType type) {
    switch (type) {
      case MediaType.image:
        return 'images';
      case MediaType.video:
        return 'videos';
      case MediaType.audio:
        return 'audio';
      case MediaType.document:
        return 'documents';
      case MediaType.file:
        return 'files';
    }
  }

  /// Create image thumbnail (placeholder - would use image processing library in production)
  Future<Uint8List?> _createImageThumbnail(File imageFile, int maxWidth, int maxHeight) async {
    try {
      // This is a placeholder - in production you'd use packages like:
      // - flutter_image_compress
      // - image package
      // For now, just return the original file bytes (limited)
      return await imageFile.readAsBytes();
    } catch (e) {
      debugPrint('Error creating image thumbnail: $e');
      return null;
    }
  }

  /// Create video thumbnail (placeholder)
  Future<Uint8List?> _createVideoThumbnail(File videoFile) async {
    try {
      // This is a placeholder - in production you'd use packages like:
      // - video_thumbnail
      // - ffmpeg_kit_flutter
      debugPrint('Video thumbnail creation not implemented');
      return null;
    } catch (e) {
      debugPrint('Error creating video thumbnail: $e');
      return null;
    }
  }

  /// Get human readable file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file is an image
  bool isImage(String mimeType) => mimeType.startsWith('image/');

  /// Check if file is a video
  bool isVideo(String mimeType) => mimeType.startsWith('video/');

  /// Check if file is audio
  bool isAudio(String mimeType) => mimeType.startsWith('audio/');

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      List<FileSystemEntity> files = tempDir.listSync();
      
      for (FileSystemEntity file in files) {
        if (file is File && 
            (file.path.contains('compressed_') || 
             file.path.contains('thumbnail_') ||
             file.path.contains('temp_media'))) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }
}

/// Media file wrapper
class MediaFile {
  final File file;
  final MediaType type;
  final String mimeType;
  final int size;
  final String name;
  final DateTime createdAt;
  Uint8List? thumbnail;

  MediaFile({
    required this.file,
    required this.type,
    required this.mimeType,
    required this.size,
    required this.name,
    this.thumbnail,
  }) : createdAt = DateTime.now();

  String get sizeFormatted => MediaMessageService.instance.formatFileSize(size);
  String get extension => path.extension(name);
  bool get isImage => MediaMessageService.instance.isImage(mimeType);
  bool get isVideo => MediaMessageService.instance.isVideo(mimeType);
  bool get isAudio => MediaMessageService.instance.isAudio(mimeType);
}

/// Media types
enum MediaType {
  image,
  video,
  audio,
  document,
  file,
}