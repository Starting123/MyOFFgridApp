enum MessageStatus {
  pending,    // Message created but not sent
  sent,       // Message sent to nearby devices
  delivered,  // Message delivered to at least one device
  synced,     // Message synced to cloud
  failed      // Message failed to send
}

enum MessageType {
  text,
  image,
  video,
  file,
  sos,
  location
}

class EnhancedMessageModel {
  final String id;
  final String senderId;
  final String? receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final bool isSOS;
  final bool isEncrypted;
  final String? filePath;        // For media messages
  final String? thumbnailPath;   // For video messages
  final double? latitude;        // For location messages
  final double? longitude;       // For location messages
  final String? encryptionKey;   // Unique key for this message
  final DateTime? deliveredAt;
  final DateTime? syncedAt;
  final List<String>? deliveredTo; // Track which devices received it

  const EnhancedMessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.pending,
    this.isSOS = false,
    this.isEncrypted = false,
    this.filePath,
    this.thumbnailPath,
    this.latitude,
    this.longitude,
    this.encryptionKey,
    this.deliveredAt,
    this.syncedAt,
    this.deliveredTo,
  });

  EnhancedMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    bool? isSOS,
    bool? isEncrypted,
    String? filePath,
    String? thumbnailPath,
    double? latitude,
    double? longitude,
    String? encryptionKey,
    DateTime? deliveredAt,
    DateTime? syncedAt,
    List<String>? deliveredTo,
  }) {
    return EnhancedMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      isSOS: isSOS ?? this.isSOS,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deliveredTo: deliveredTo ?? this.deliveredTo,
    );
  }

  factory EnhancedMessageModel.fromJson(Map<String, dynamic> json) {
    return EnhancedMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.pending,
      ),
      isSOS: json['isSOS'] as bool? ?? false,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      filePath: json['filePath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      encryptionKey: json['encryptionKey'] as String?,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.parse(json['deliveredAt'] as String) 
          : null,
      syncedAt: json['syncedAt'] != null 
          ? DateTime.parse(json['syncedAt'] as String) 
          : null,
      deliveredTo: (json['deliveredTo'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'isSOS': isSOS,
      'isEncrypted': isEncrypted,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'latitude': latitude,
      'longitude': longitude,
      'encryptionKey': encryptionKey,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'deliveredTo': deliveredTo,
    };
  }
}

// Extension for easy status checking
extension MessageStatusExtension on EnhancedMessageModel {
  bool get isPending => status == MessageStatus.pending;
  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isSynced => status == MessageStatus.synced;
  bool get hasFailed => status == MessageStatus.failed;
  
  bool get isMediaMessage => type == MessageType.image || 
                           type == MessageType.video || 
                           type == MessageType.file;
                           
  String get statusDisplayText {
    switch (status) {
      case MessageStatus.pending:
        return 'ค้างส่ง';
      case MessageStatus.sent:
        return 'ส่งแล้ว';
      case MessageStatus.delivered:
        return 'ส่งถึง';
      case MessageStatus.synced:
        return 'ซิงก์แล้ว';
      case MessageStatus.failed:
        return 'ส่งไม่สำเร็จ';
    }
  }
}