// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

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
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<String> fromId = GeneratedColumn<String>(
      'from_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<String> toId = GeneratedColumn<String>(
      'to_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _ttlMeta = const VerificationMeta('ttl');
  @override
  late final GeneratedColumn<int> ttl = GeneratedColumn<int>(
      'ttl', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(24));
  static const VerificationMeta _hopCountMeta =
      const VerificationMeta('hopCount');
  @override
  late final GeneratedColumn<int> hopCount = GeneratedColumn<int>(
      'hop_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        fromId,
        toId,
        type,
        body,
        filePath,
        timestamp,
        status,
        ttl,
        hopCount
      ];
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
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('from_id')) {
      context.handle(_fromIdMeta,
          fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta));
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
          _toIdMeta, toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta));
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('ttl')) {
      context.handle(
          _ttlMeta, ttl.isAcceptableOrUnknown(data['ttl']!, _ttlMeta));
    }
    if (data.containsKey('hop_count')) {
      context.handle(_hopCountMeta,
          hopCount.isAcceptableOrUnknown(data['hop_count']!, _hopCountMeta));
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
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      fromId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_id'])!,
      toId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      ttl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ttl'])!,
      hopCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hop_count'])!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final String messageId;
  final String fromId;
  final String toId;
  final String type;
  final String body;
  final String? filePath;
  final DateTime timestamp;
  final String status;
  final int ttl;
  final int hopCount;
  const Message(
      {required this.id,
      required this.messageId,
      required this.fromId,
      required this.toId,
      required this.type,
      required this.body,
      this.filePath,
      required this.timestamp,
      required this.status,
      required this.ttl,
      required this.hopCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['from_id'] = Variable<String>(fromId);
    map['to_id'] = Variable<String>(toId);
    map['type'] = Variable<String>(type);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['status'] = Variable<String>(status);
    map['ttl'] = Variable<int>(ttl);
    map['hop_count'] = Variable<int>(hopCount);
    return map;
  }

  MessageCompanion toCompanion(bool nullToAbsent) {
    return MessageCompanion(
      id: Value(id),
      messageId: Value(messageId),
      fromId: Value(fromId),
      toId: Value(toId),
      type: Value(type),
      body: Value(body),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      timestamp: Value(timestamp),
      status: Value(status),
      ttl: Value(ttl),
      hopCount: Value(hopCount),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      fromId: serializer.fromJson<String>(json['fromId']),
      toId: serializer.fromJson<String>(json['toId']),
      type: serializer.fromJson<String>(json['type']),
      body: serializer.fromJson<String>(json['body']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      status: serializer.fromJson<String>(json['status']),
      ttl: serializer.fromJson<int>(json['ttl']),
      hopCount: serializer.fromJson<int>(json['hopCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'fromId': serializer.toJson<String>(fromId),
      'toId': serializer.toJson<String>(toId),
      'type': serializer.toJson<String>(type),
      'body': serializer.toJson<String>(body),
      'filePath': serializer.toJson<String?>(filePath),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'status': serializer.toJson<String>(status),
      'ttl': serializer.toJson<int>(ttl),
      'hopCount': serializer.toJson<int>(hopCount),
    };
  }

  Message copyWith(
          {int? id,
          String? messageId,
          String? fromId,
          String? toId,
          String? type,
          String? body,
          Value<String?> filePath = const Value.absent(),
          DateTime? timestamp,
          String? status,
          int? ttl,
          int? hopCount}) =>
      Message(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
        type: type ?? this.type,
        body: body ?? this.body,
        filePath: filePath.present ? filePath.value : this.filePath,
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        ttl: ttl ?? this.ttl,
        hopCount: hopCount ?? this.hopCount,
      );
  Message copyWithCompanion(MessageCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      type: data.type.present ? data.type.value : this.type,
      body: data.body.present ? data.body.value : this.body,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
      ttl: data.ttl.present ? data.ttl.value : this.ttl,
      hopCount: data.hopCount.present ? data.hopCount.value : this.hopCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('filePath: $filePath, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('ttl: $ttl, ')
          ..write('hopCount: $hopCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, fromId, toId, type, body,
      filePath, timestamp, status, ttl, hopCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.type == this.type &&
          other.body == this.body &&
          other.filePath == this.filePath &&
          other.timestamp == this.timestamp &&
          other.status == this.status &&
          other.ttl == this.ttl &&
          other.hopCount == this.hopCount);
}

class MessageCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> fromId;
  final Value<String> toId;
  final Value<String> type;
  final Value<String> body;
  final Value<String?> filePath;
  final Value<DateTime> timestamp;
  final Value<String> status;
  final Value<int> ttl;
  final Value<int> hopCount;
  const MessageCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.type = const Value.absent(),
    this.body = const Value.absent(),
    this.filePath = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.ttl = const Value.absent(),
    this.hopCount = const Value.absent(),
  });
  MessageCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String fromId,
    required String toId,
    required String type,
    required String body,
    this.filePath = const Value.absent(),
    required DateTime timestamp,
    this.status = const Value.absent(),
    this.ttl = const Value.absent(),
    this.hopCount = const Value.absent(),
  })  : messageId = Value(messageId),
        fromId = Value(fromId),
        toId = Value(toId),
        type = Value(type),
        body = Value(body),
        timestamp = Value(timestamp);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? fromId,
    Expression<String>? toId,
    Expression<String>? type,
    Expression<String>? body,
    Expression<String>? filePath,
    Expression<DateTime>? timestamp,
    Expression<String>? status,
    Expression<int>? ttl,
    Expression<int>? hopCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (type != null) 'type': type,
      if (body != null) 'body': body,
      if (filePath != null) 'file_path': filePath,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
      if (ttl != null) 'ttl': ttl,
      if (hopCount != null) 'hop_count': hopCount,
    });
  }

  MessageCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<String>? fromId,
      Value<String>? toId,
      Value<String>? type,
      Value<String>? body,
      Value<String?>? filePath,
      Value<DateTime>? timestamp,
      Value<String>? status,
      Value<int>? ttl,
      Value<int>? hopCount}) {
    return MessageCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      type: type ?? this.type,
      body: body ?? this.body,
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (fromId.present) {
      map['from_id'] = Variable<String>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<String>(toId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (ttl.present) {
      map['ttl'] = Variable<int>(ttl.value);
    }
    if (hopCount.present) {
      map['hop_count'] = Variable<int>(hopCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('filePath: $filePath, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('ttl: $ttl, ')
          ..write('hopCount: $hopCount')
          ..write(')'))
        .toString();
  }
}

class $QueueItemsTable extends QueueItems
    with TableInfo<$QueueItemsTable, QueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetIdMeta =
      const VerificationMeta('targetId');
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
      'target_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nextAttemptMeta =
      const VerificationMeta('nextAttempt');
  @override
  late final GeneratedColumn<DateTime> nextAttempt = GeneratedColumn<DateTime>(
      'next_attempt', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, messageId, targetId, nextAttempt, attempts, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_items';
  @override
  VerificationContext validateIntegrity(Insertable<QueueItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(_targetIdMeta,
          targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta));
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('next_attempt')) {
      context.handle(
          _nextAttemptMeta,
          nextAttempt.isAcceptableOrUnknown(
              data['next_attempt']!, _nextAttemptMeta));
    } else if (isInserting) {
      context.missing(_nextAttemptMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      targetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_id'])!,
      nextAttempt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_attempt'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $QueueItemsTable createAlias(String alias) {
    return $QueueItemsTable(attachedDatabase, alias);
  }
}

class QueueItem extends DataClass implements Insertable<QueueItem> {
  final int id;
  final String messageId;
  final String targetId;
  final DateTime nextAttempt;
  final int attempts;
  final String status;
  const QueueItem(
      {required this.id,
      required this.messageId,
      required this.targetId,
      required this.nextAttempt,
      required this.attempts,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['target_id'] = Variable<String>(targetId);
    map['next_attempt'] = Variable<DateTime>(nextAttempt);
    map['attempts'] = Variable<int>(attempts);
    map['status'] = Variable<String>(status);
    return map;
  }

  QueueItemCompanion toCompanion(bool nullToAbsent) {
    return QueueItemCompanion(
      id: Value(id),
      messageId: Value(messageId),
      targetId: Value(targetId),
      nextAttempt: Value(nextAttempt),
      attempts: Value(attempts),
      status: Value(status),
    );
  }

  factory QueueItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueItem(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      nextAttempt: serializer.fromJson<DateTime>(json['nextAttempt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'targetId': serializer.toJson<String>(targetId),
      'nextAttempt': serializer.toJson<DateTime>(nextAttempt),
      'attempts': serializer.toJson<int>(attempts),
      'status': serializer.toJson<String>(status),
    };
  }

  QueueItem copyWith(
          {int? id,
          String? messageId,
          String? targetId,
          DateTime? nextAttempt,
          int? attempts,
          String? status}) =>
      QueueItem(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        targetId: targetId ?? this.targetId,
        nextAttempt: nextAttempt ?? this.nextAttempt,
        attempts: attempts ?? this.attempts,
        status: status ?? this.status,
      );
  QueueItem copyWithCompanion(QueueItemCompanion data) {
    return QueueItem(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      nextAttempt:
          data.nextAttempt.present ? data.nextAttempt.value : this.nextAttempt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueItem(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('targetId: $targetId, ')
          ..write('nextAttempt: $nextAttempt, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, messageId, targetId, nextAttempt, attempts, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueItem &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.targetId == this.targetId &&
          other.nextAttempt == this.nextAttempt &&
          other.attempts == this.attempts &&
          other.status == this.status);
}

class QueueItemCompanion extends UpdateCompanion<QueueItem> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> targetId;
  final Value<DateTime> nextAttempt;
  final Value<int> attempts;
  final Value<String> status;
  const QueueItemCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.nextAttempt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
  });
  QueueItemCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String targetId,
    required DateTime nextAttempt,
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
  })  : messageId = Value(messageId),
        targetId = Value(targetId),
        nextAttempt = Value(nextAttempt);
  static Insertable<QueueItem> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? targetId,
    Expression<DateTime>? nextAttempt,
    Expression<int>? attempts,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (targetId != null) 'target_id': targetId,
      if (nextAttempt != null) 'next_attempt': nextAttempt,
      if (attempts != null) 'attempts': attempts,
      if (status != null) 'status': status,
    });
  }

  QueueItemCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<String>? targetId,
      Value<DateTime>? nextAttempt,
      Value<int>? attempts,
      Value<String>? status}) {
    return QueueItemCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      targetId: targetId ?? this.targetId,
      nextAttempt: nextAttempt ?? this.nextAttempt,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (nextAttempt.present) {
      map['next_attempt'] = Variable<DateTime>(nextAttempt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueItemCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('targetId: $targetId, ')
          ..write('nextAttempt: $nextAttempt, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncLogsTable extends SyncLogs with TableInfo<$SyncLogsTable, SyncLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, messageId, operation, timestamp, status, error];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
    );
  }

  @override
  $SyncLogsTable createAlias(String alias) {
    return $SyncLogsTable(attachedDatabase, alias);
  }
}

class SyncLog extends DataClass implements Insertable<SyncLog> {
  final int id;
  final String messageId;
  final String operation;
  final DateTime timestamp;
  final String status;
  final String? error;
  const SyncLog(
      {required this.id,
      required this.messageId,
      required this.operation,
      required this.timestamp,
      required this.status,
      this.error});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['operation'] = Variable<String>(operation);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      id: Value(id),
      messageId: Value(messageId),
      operation: Value(operation),
      timestamp: Value(timestamp),
      status: Value(status),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
    );
  }

  factory SyncLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLog(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      operation: serializer.fromJson<String>(json['operation']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      status: serializer.fromJson<String>(json['status']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'operation': serializer.toJson<String>(operation),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'status': serializer.toJson<String>(status),
      'error': serializer.toJson<String?>(error),
    };
  }

  SyncLog copyWith(
          {int? id,
          String? messageId,
          String? operation,
          DateTime? timestamp,
          String? status,
          Value<String?> error = const Value.absent()}) =>
      SyncLog(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        operation: operation ?? this.operation,
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        error: error.present ? error.value : this.error,
      );
  SyncLog copyWithCompanion(SyncLogCompanion data) {
    return SyncLog(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      operation: data.operation.present ? data.operation.value : this.operation,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLog(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('operation: $operation, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, messageId, operation, timestamp, status, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLog &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.operation == this.operation &&
          other.timestamp == this.timestamp &&
          other.status == this.status &&
          other.error == this.error);
}

class SyncLogCompanion extends UpdateCompanion<SyncLog> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> operation;
  final Value<DateTime> timestamp;
  final Value<String> status;
  final Value<String?> error;
  const SyncLogCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.operation = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
  });
  SyncLogCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String operation,
    required DateTime timestamp,
    required String status,
    this.error = const Value.absent(),
  })  : messageId = Value(messageId),
        operation = Value(operation),
        timestamp = Value(timestamp),
        status = Value(status);
  static Insertable<SyncLog> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? operation,
    Expression<DateTime>? timestamp,
    Expression<String>? status,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (operation != null) 'operation': operation,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
    });
  }

  SyncLogCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<String>? operation,
      Value<DateTime>? timestamp,
      Value<String>? status,
      Value<String?>? error}) {
    return SyncLogCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      operation: operation ?? this.operation,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('operation: $operation, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $QueueItemsTable queueItems = $QueueItemsTable(this);
  late final $SyncLogsTable syncLogs = $SyncLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [messages, queueItems, syncLogs];
}

typedef $$MessagesTableCreateCompanionBuilder = MessageCompanion Function({
  Value<int> id,
  required String messageId,
  required String fromId,
  required String toId,
  required String type,
  required String body,
  Value<String?> filePath,
  required DateTime timestamp,
  Value<String> status,
  Value<int> ttl,
  Value<int> hopCount,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessageCompanion Function({
  Value<int> id,
  Value<String> messageId,
  Value<String> fromId,
  Value<String> toId,
  Value<String> type,
  Value<String> body,
  Value<String?> filePath,
  Value<DateTime> timestamp,
  Value<String> status,
  Value<int> ttl,
  Value<int> hopCount,
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

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ttl => $composableBuilder(
      column: $table.ttl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hopCount => $composableBuilder(
      column: $table.hopCount, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ttl => $composableBuilder(
      column: $table.ttl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hopCount => $composableBuilder(
      column: $table.hopCount, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<String> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get ttl =>
      $composableBuilder(column: $table.ttl, builder: (column) => column);

  GeneratedColumn<int> get hopCount =>
      $composableBuilder(column: $table.hopCount, builder: (column) => column);
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
            Value<String> messageId = const Value.absent(),
            Value<String> fromId = const Value.absent(),
            Value<String> toId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> ttl = const Value.absent(),
            Value<int> hopCount = const Value.absent(),
          }) =>
              MessageCompanion(
            id: id,
            messageId: messageId,
            fromId: fromId,
            toId: toId,
            type: type,
            body: body,
            filePath: filePath,
            timestamp: timestamp,
            status: status,
            ttl: ttl,
            hopCount: hopCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            required String fromId,
            required String toId,
            required String type,
            required String body,
            Value<String?> filePath = const Value.absent(),
            required DateTime timestamp,
            Value<String> status = const Value.absent(),
            Value<int> ttl = const Value.absent(),
            Value<int> hopCount = const Value.absent(),
          }) =>
              MessageCompanion.insert(
            id: id,
            messageId: messageId,
            fromId: fromId,
            toId: toId,
            type: type,
            body: body,
            filePath: filePath,
            timestamp: timestamp,
            status: status,
            ttl: ttl,
            hopCount: hopCount,
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
typedef $$QueueItemsTableCreateCompanionBuilder = QueueItemCompanion Function({
  Value<int> id,
  required String messageId,
  required String targetId,
  required DateTime nextAttempt,
  Value<int> attempts,
  Value<String> status,
});
typedef $$QueueItemsTableUpdateCompanionBuilder = QueueItemCompanion Function({
  Value<int> id,
  Value<String> messageId,
  Value<String> targetId,
  Value<DateTime> nextAttempt,
  Value<int> attempts,
  Value<String> status,
});

class $$QueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $QueueItemsTable> {
  $$QueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttempt => $composableBuilder(
      column: $table.nextAttempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$QueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueItemsTable> {
  $$QueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttempt => $composableBuilder(
      column: $table.nextAttempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$QueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueItemsTable> {
  $$QueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttempt => $composableBuilder(
      column: $table.nextAttempt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$QueueItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QueueItemsTable,
    QueueItem,
    $$QueueItemsTableFilterComposer,
    $$QueueItemsTableOrderingComposer,
    $$QueueItemsTableAnnotationComposer,
    $$QueueItemsTableCreateCompanionBuilder,
    $$QueueItemsTableUpdateCompanionBuilder,
    (QueueItem, BaseReferences<_$AppDatabase, $QueueItemsTable, QueueItem>),
    QueueItem,
    PrefetchHooks Function()> {
  $$QueueItemsTableTableManager(_$AppDatabase db, $QueueItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> targetId = const Value.absent(),
            Value<DateTime> nextAttempt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              QueueItemCompanion(
            id: id,
            messageId: messageId,
            targetId: targetId,
            nextAttempt: nextAttempt,
            attempts: attempts,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            required String targetId,
            required DateTime nextAttempt,
            Value<int> attempts = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              QueueItemCompanion.insert(
            id: id,
            messageId: messageId,
            targetId: targetId,
            nextAttempt: nextAttempt,
            attempts: attempts,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QueueItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QueueItemsTable,
    QueueItem,
    $$QueueItemsTableFilterComposer,
    $$QueueItemsTableOrderingComposer,
    $$QueueItemsTableAnnotationComposer,
    $$QueueItemsTableCreateCompanionBuilder,
    $$QueueItemsTableUpdateCompanionBuilder,
    (QueueItem, BaseReferences<_$AppDatabase, $QueueItemsTable, QueueItem>),
    QueueItem,
    PrefetchHooks Function()>;
typedef $$SyncLogsTableCreateCompanionBuilder = SyncLogCompanion Function({
  Value<int> id,
  required String messageId,
  required String operation,
  required DateTime timestamp,
  required String status,
  Value<String?> error,
});
typedef $$SyncLogsTableUpdateCompanionBuilder = SyncLogCompanion Function({
  Value<int> id,
  Value<String> messageId,
  Value<String> operation,
  Value<DateTime> timestamp,
  Value<String> status,
  Value<String?> error,
});

class $$SyncLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));
}

class $$SyncLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));
}

class $$SyncLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogsTable> {
  $$SyncLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SyncLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncLogsTable,
    SyncLog,
    $$SyncLogsTableFilterComposer,
    $$SyncLogsTableOrderingComposer,
    $$SyncLogsTableAnnotationComposer,
    $$SyncLogsTableCreateCompanionBuilder,
    $$SyncLogsTableUpdateCompanionBuilder,
    (SyncLog, BaseReferences<_$AppDatabase, $SyncLogsTable, SyncLog>),
    SyncLog,
    PrefetchHooks Function()> {
  $$SyncLogsTableTableManager(_$AppDatabase db, $SyncLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> error = const Value.absent(),
          }) =>
              SyncLogCompanion(
            id: id,
            messageId: messageId,
            operation: operation,
            timestamp: timestamp,
            status: status,
            error: error,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            required String operation,
            required DateTime timestamp,
            required String status,
            Value<String?> error = const Value.absent(),
          }) =>
              SyncLogCompanion.insert(
            id: id,
            messageId: messageId,
            operation: operation,
            timestamp: timestamp,
            status: status,
            error: error,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncLogsTable,
    SyncLog,
    $$SyncLogsTableFilterComposer,
    $$SyncLogsTableOrderingComposer,
    $$SyncLogsTableAnnotationComposer,
    $$SyncLogsTableCreateCompanionBuilder,
    $$SyncLogsTableUpdateCompanionBuilder,
    (SyncLog, BaseReferences<_$AppDatabase, $SyncLogsTable, SyncLog>),
    SyncLog,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$QueueItemsTableTableManager get queueItems =>
      $$QueueItemsTableTableManager(_db, _db.queueItems);
  $$SyncLogsTableTableManager get syncLogs =>
      $$SyncLogsTableTableManager(_db, _db.syncLogs);
}
