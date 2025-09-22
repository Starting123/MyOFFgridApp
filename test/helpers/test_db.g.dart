// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_db.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _receiverIdMeta =
      const VerificationMeta('receiverId');
  @override
  late final GeneratedColumn<String> receiverId = GeneratedColumn<String>(
      'receiver_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedContentMeta =
      const VerificationMeta('encryptedContent');
  @override
  late final GeneratedColumn<String> encryptedContent = GeneratedColumn<String>(
      'encrypted_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, senderId, receiverId, encryptedContent, timestamp, isRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('receiver_id')) {
      context.handle(
          _receiverIdMeta,
          receiverId.isAcceptableOrUnknown(
              data['receiver_id']!, _receiverIdMeta));
    } else if (isInserting) {
      context.missing(_receiverIdMeta);
    }
    if (data.containsKey('encrypted_content')) {
      context.handle(
          _encryptedContentMeta,
          encryptedContent.isAcceptableOrUnknown(
              data['encrypted_content']!, _encryptedContentMeta));
    } else if (isInserting) {
      context.missing(_encryptedContentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      receiverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receiver_id'])!,
      encryptedContent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}encrypted_content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final String senderId;
  final String receiverId;
  final String encryptedContent;
  final DateTime timestamp;
  final bool isRead;
  const Message(
      {required this.id,
      required this.senderId,
      required this.receiverId,
      required this.encryptedContent,
      required this.timestamp,
      required this.isRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_id'] = Variable<String>(senderId);
    map['receiver_id'] = Variable<String>(receiverId);
    map['encrypted_content'] = Variable<String>(encryptedContent);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  MessageCompanion toCompanion(bool nullToAbsent) {
    return MessageCompanion(
      id: Value(id),
      senderId: Value(senderId),
      receiverId: Value(receiverId),
      encryptedContent: Value(encryptedContent),
      timestamp: Value(timestamp),
      isRead: Value(isRead),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      senderId: serializer.fromJson<String>(json['senderId']),
      receiverId: serializer.fromJson<String>(json['receiverId']),
      encryptedContent: serializer.fromJson<String>(json['encryptedContent']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'senderId': serializer.toJson<String>(senderId),
      'receiverId': serializer.toJson<String>(receiverId),
      'encryptedContent': serializer.toJson<String>(encryptedContent),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  Message copyWith(
          {int? id,
          String? senderId,
          String? receiverId,
          String? encryptedContent,
          DateTime? timestamp,
          bool? isRead}) =>
      Message(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        receiverId: receiverId ?? this.receiverId,
        encryptedContent: encryptedContent ?? this.encryptedContent,
        timestamp: timestamp ?? this.timestamp,
        isRead: isRead ?? this.isRead,
      );
  Message copyWithCompanion(MessageCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      receiverId:
          data.receiverId.present ? data.receiverId.value : this.receiverId,
      encryptedContent: data.encryptedContent.present
          ? data.encryptedContent.value
          : this.encryptedContent,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('receiverId: $receiverId, ')
          ..write('encryptedContent: $encryptedContent, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, senderId, receiverId, encryptedContent, timestamp, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.senderId == this.senderId &&
          other.receiverId == this.receiverId &&
          other.encryptedContent == this.encryptedContent &&
          other.timestamp == this.timestamp &&
          other.isRead == this.isRead);
}

class MessageCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String> senderId;
  final Value<String> receiverId;
  final Value<String> encryptedContent;
  final Value<DateTime> timestamp;
  final Value<bool> isRead;
  const MessageCompanion({
    this.id = const Value.absent(),
    this.senderId = const Value.absent(),
    this.receiverId = const Value.absent(),
    this.encryptedContent = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRead = const Value.absent(),
  });
  MessageCompanion.insert({
    this.id = const Value.absent(),
    required String senderId,
    required String receiverId,
    required String encryptedContent,
    required DateTime timestamp,
    this.isRead = const Value.absent(),
  })  : senderId = Value(senderId),
        receiverId = Value(receiverId),
        encryptedContent = Value(encryptedContent),
        timestamp = Value(timestamp);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? senderId,
    Expression<String>? receiverId,
    Expression<String>? encryptedContent,
    Expression<DateTime>? timestamp,
    Expression<bool>? isRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (receiverId != null) 'receiver_id': receiverId,
      if (encryptedContent != null) 'encrypted_content': encryptedContent,
      if (timestamp != null) 'timestamp': timestamp,
      if (isRead != null) 'is_read': isRead,
    });
  }

  MessageCompanion copyWith(
      {Value<int>? id,
      Value<String>? senderId,
      Value<String>? receiverId,
      Value<String>? encryptedContent,
      Value<DateTime>? timestamp,
      Value<bool>? isRead}) {
    return MessageCompanion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (receiverId.present) {
      map['receiver_id'] = Variable<String>(receiverId.value);
    }
    if (encryptedContent.present) {
      map['encrypted_content'] = Variable<String>(encryptedContent.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageCompanion(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('receiverId: $receiverId, ')
          ..write('encryptedContent: $encryptedContent, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [messages];
}

typedef $$MessagesTableCreateCompanionBuilder = MessageCompanion Function({
  Value<int> id,
  required String senderId,
  required String receiverId,
  required String encryptedContent,
  required DateTime timestamp,
  Value<bool> isRead,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessageCompanion Function({
  Value<int> id,
  Value<String> senderId,
  Value<String> receiverId,
  Value<String> encryptedContent,
  Value<DateTime> timestamp,
  Value<bool> isRead,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiverId => $composableBuilder(
      column: $table.receiverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptedContent => $composableBuilder(
      column: $table.encryptedContent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiverId => $composableBuilder(
      column: $table.receiverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptedContent => $composableBuilder(
      column: $table.encryptedContent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get receiverId => $composableBuilder(
      column: $table.receiverId, builder: (column) => column);

  GeneratedColumn<String> get encryptedContent => $composableBuilder(
      column: $table.encryptedContent, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String> receiverId = const Value.absent(),
            Value<String> encryptedContent = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
          }) =>
              MessageCompanion(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            encryptedContent: encryptedContent,
            timestamp: timestamp,
            isRead: isRead,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String senderId,
            required String receiverId,
            required String encryptedContent,
            required DateTime timestamp,
            Value<bool> isRead = const Value.absent(),
          }) =>
              MessageCompanion.insert(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            encryptedContent: encryptedContent,
            timestamp: timestamp,
            isRead: isRead,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}
