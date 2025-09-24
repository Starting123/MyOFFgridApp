import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'db.g.dart';

// Define tables
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text().nullable()();
  BoolColumn get isSos => boolean().withDefault(const Constant(false))();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get lastSeen => dateTime()();
  TextColumn get deviceType => text()(); // 'sos' or 'rescuer'
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Messages, Devices])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Messages operations
  Future<List<Message>> getAllMessages() => select(messages).get();
  
  Future<List<Message>> getUnsynedMessages() => 
    (select(messages)..where((m) => m.isSynced.equals(false))).get();

  Future<int> insertMessage(MessageCompanion message) =>
      into(messages).insert(message);

  Future<bool> updateMessageSyncStatus(int id, bool synced) async {
    final result = await (update(messages)..where((m) => m.id.equals(id)))
      .write(MessageCompanion(isSynced: Value(synced)));
    return result > 0;
  }

  // Device operations
  Future<List<Device>> getAllDevices() => select(devices).get();

  Future<int> upsertDevice(DeviceCompanion device) =>
      into(devices).insertOnConflictUpdate(device);

  Future<int> removeOldDevices(DateTime cutoff) =>
    (delete(devices)..where((d) => d.lastSeen.isSmallerThanValue(cutoff))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'offgrid_sos.db'));
    return NativeDatabase.createInBackground(file);
  });
}