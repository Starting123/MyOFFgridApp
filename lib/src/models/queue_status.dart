enum QueueStatus {
  pending,
  processing,
  completed,
  failed
}

extension QueueStatusExtension on QueueStatus {
  String toValue() {
    return toString().split('.').last;
  }

  static QueueStatus fromValue(String value) {
    return QueueStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => QueueStatus.pending,
    );
  }
}