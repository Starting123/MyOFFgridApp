
import '../data/db.dart';
import '../data/models/message_model.dart';

class SyncService {
  final AppDatabase db;

  SyncService(this.db);

  /// Basic sync: read messages and mark unsent as sent (placeholder)
  Future<void> sync() async {
    final all = await db.getAllMessages();
    for (final m in all) {
      if (!m.sent) {
        // TODO: actually send to {CLOUD_ENDPOINT} using http and on success update
        final updated = MessageModel(
          id: m.id,
          from: m.from,
          to: m.to,
          content: m.content,
          contentType: m.contentType,
          createdAt: m.createdAt,
          sent: true,
        );
        await db.updateMessage(updated);
      }
    }
  }
}



