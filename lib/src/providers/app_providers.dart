import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db.dart';
import '../services/sync_service.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.read(dbProvider);
  return SyncService(db);
});
