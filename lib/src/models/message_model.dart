class MessageModel {
  final String id;
  final String senderId;
  final String? receiverId;
  final String content;
  final DateTime timestamp;
  final bool isSOS;
  final bool isSynced;

  MessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.content,
    required this.timestamp,
    this.isSOS = false,
    this.isSynced = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSOS: json['isSOS'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isSOS': isSOS,
      'isSynced': isSynced,
    };
  }
}