class QueueItem {
  final int id;
  final int messageId;
  final String type;
  final int priority;
  final int retryCount;
  final DateTime nextRetry;
  final DateTime createdAt;

  QueueItem({
    required this.id,
    required this.messageId,
    required this.type,
    required this.priority,
    required this.retryCount,
    required this.nextRetry,
    required this.createdAt,
  });

  QueueItem copyWith({
    int? id,
    int? messageId,
    String? type,
    int? priority,
    int? retryCount,
    DateTime? nextRetry,
    DateTime? createdAt,
  }) {
    return QueueItem(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      nextRetry: nextRetry ?? this.nextRetry,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}