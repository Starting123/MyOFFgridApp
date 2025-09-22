enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
  synced
}

extension MessageStatusExtension on MessageStatus {
  String toValue() {
    return toString().split('.').last;
  }

  static MessageStatus fromValue(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => MessageStatus.pending,
    );
  }
}