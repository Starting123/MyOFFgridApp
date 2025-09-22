class QueueItem {
  final int id;
  final String messageId;
  final String targetId;
  final DateTime nextAttempt;
  final int attempts;
  final String status;

  QueueItem({
    required this.id,
    required this.messageId,
    required this.targetId,
    required this.nextAttempt,
    required this.attempts,
    required this.status,
  });

  QueueItem copyWith({
    int? id,
    String? messageId,
    String? targetId,
    DateTime? nextAttempt,
    int? attempts,
    String? status,
  }) {
    return QueueItem(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      targetId: targetId ?? this.targetId,
      nextAttempt: nextAttempt ?? this.nextAttempt,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
    );
  }

  factory QueueItem.fromMap(Map<String, dynamic> map) {
    return QueueItem(
      id: map['id'] as int,
      messageId: map['messageId'] as String,
      targetId: map['targetId'] as String,
      nextAttempt: DateTime.parse(map['nextAttempt'] as String),
      attempts: map['attempts'] as int,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messageId': messageId,
      'targetId': targetId,
      'nextAttempt': nextAttempt.toIso8601String(),
      'attempts': attempts,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'QueueItem{id: $id, messageId: $messageId, targetId: $targetId, nextAttempt: $nextAttempt, attempts: $attempts, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueueItem &&
        other.id == id &&
        other.messageId == messageId &&
        other.targetId == targetId &&
        other.nextAttempt == nextAttempt &&
        other.attempts == attempts &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        messageId.hashCode ^
        targetId.hashCode ^
        nextAttempt.hashCode ^
        attempts.hashCode ^
        status.hashCode;
  }
}