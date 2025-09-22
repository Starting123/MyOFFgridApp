import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models/message_model.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'offgrid_sos.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            from TEXT,
            to TEXT,
            content TEXT,
            contentType TEXT,
            createdAt TEXT,
            sent INTEGER
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertMessage(MessageModel m) async {
    final db = await database;
    await db.insert('messages', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageModel>> getAllMessages() async {
    final db = await database;
    final rows = await db.query('messages', orderBy: 'createdAt DESC');
    return rows.map((r) => MessageModel.fromMap(r)).toList();
  }

  Future<void> updateMessage(MessageModel m) async {
    final db = await database;
    await db.update('messages', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }
}

