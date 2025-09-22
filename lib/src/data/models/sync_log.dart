class SyncLog {
  final int id;
  final String type;
  final int itemId;
  final String details;
  final DateTime createdAt;

  SyncLog({
    required this.id,
    required this.type,
    required this.itemId,
    required this.details,
    required this.createdAt,
  });
}