class MessageModel {
  final String id;
  final String from;
  final String to;
  final String content;
  final String contentType; // text/image/video
  final DateTime createdAt;
  final bool sent;

  MessageModel({
    required this.id,
    required this.from,
    required this.to,
    required this.content,
    required this.contentType,
    required this.createdAt,
    required this.sent,
  });

  factory MessageModel.fromMap(Map<String, dynamic> m) => MessageModel(
        id: m['id'] as String,
        from: m['from'] as String,
        to: m['to'] as String,
        content: m['content'] as String,
        contentType: m['contentType'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        sent: (m['sent'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'from': from,
        'to': to,
        'content': content,
        'contentType': contentType,
        'createdAt': createdAt.toIso8601String(),
        'sent': sent ? 1 : 0,
      };
}

