// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_db.dart';

// ignore_for_file: type=lint
class $EnhancedMessagesTable extends EnhancedMessages
    with TableInfo<$EnhancedMessagesTable, EnhancedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnhancedMessagesTable(this.attachedDatabase, [this._alias]);
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
      'receiver_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<MessageType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<MessageType>($EnhancedMessagesTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<MessageStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<MessageStatus>(
              $EnhancedMessagesTable.$converterstatus);
  static const VerificationMeta _isSosMeta = const VerificationMeta('isSos');
  @override
  late final GeneratedColumn<bool> isSos = GeneratedColumn<bool>(
      'is_sos', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_sos" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isEncryptedMeta =
      const VerificationMeta('isEncrypted');
  @override
  late final GeneratedColumn<bool> isEncrypted = GeneratedColumn<bool>(
      'is_encrypted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_encrypted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _encryptionKeyMeta =
      const VerificationMeta('encryptionKey');
  @override
  late final GeneratedColumn<String> encryptionKey = GeneratedColumn<String>(
      'encryption_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deliveredAtMeta =
      const VerificationMeta('deliveredAt');
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
      'delivered_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deliveredToMeta =
      const VerificationMeta('deliveredTo');
  @override
  late final GeneratedColumn<String> deliveredTo = GeneratedColumn<String>(
      'delivered_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        senderId,
        receiverId,
        content,
        timestamp,
        type,
        status,
        isSos,
        isEncrypted,
        filePath,
        thumbnailPath,
        latitude,
        longitude,
        encryptionKey,
        deliveredAt,
        syncedAt,
        deliveredTo,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enhanced_messages';
  @override
  VerificationContext validateIntegrity(Insertable<EnhancedMessage> instance,
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
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_sos')) {
      context.handle(
          _isSosMeta, isSos.isAcceptableOrUnknown(data['is_sos']!, _isSosMeta));
    }
    if (data.containsKey('is_encrypted')) {
      context.handle(
          _isEncryptedMeta,
          isEncrypted.isAcceptableOrUnknown(
              data['is_encrypted']!, _isEncryptedMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('encryption_key')) {
      context.handle(
          _encryptionKeyMeta,
          encryptionKey.isAcceptableOrUnknown(
              data['encryption_key']!, _encryptionKeyMeta));
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
          _deliveredAtMeta,
          deliveredAt.isAcceptableOrUnknown(
              data['delivered_at']!, _deliveredAtMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('delivered_to')) {
      context.handle(
          _deliveredToMeta,
          deliveredTo.isAcceptableOrUnknown(
              data['delivered_to']!, _deliveredToMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnhancedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnhancedMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      receiverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receiver_id']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      type: $EnhancedMessagesTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      status: $EnhancedMessagesTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      isSos: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_sos'])!,
      isEncrypted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_encrypted'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      encryptionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}encryption_key']),
      deliveredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}delivered_at']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      deliveredTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delivered_to']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EnhancedMessagesTable createAlias(String alias) {
    return $EnhancedMessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessageType, int, int> $convertertype =
      const EnumIndexConverter<MessageType>(MessageType.values);
  static JsonTypeConverter2<MessageStatus, int, int> $converterstatus =
      const EnumIndexConverter<MessageStatus>(MessageStatus.values);
}

class EnhancedMessage extends DataClass implements Insertable<EnhancedMessage> {
  final int id;
  final String messageId;
  final String senderId;
  final String? receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final bool isSos;
  final bool isEncrypted;
  final String? filePath;
  final String? thumbnailPath;
  final double? latitude;
  final double? longitude;
  final String? encryptionKey;
  final DateTime? deliveredAt;
  final DateTime? syncedAt;
  final String? deliveredTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EnhancedMessage(
      {required this.id,
      required this.messageId,
      required this.senderId,
      this.receiverId,
      required this.content,
      required this.timestamp,
      required this.type,
      required this.status,
      required this.isSos,
      required this.isEncrypted,
      this.filePath,
      this.thumbnailPath,
      this.latitude,
      this.longitude,
      this.encryptionKey,
      this.deliveredAt,
      this.syncedAt,
      this.deliveredTo,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || receiverId != null) {
      map['receiver_id'] = Variable<String>(receiverId);
    }
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<DateTime>(timestamp);
    {
      map['type'] =
          Variable<int>($EnhancedMessagesTable.$convertertype.toSql(type));
    }
    {
      map['status'] =
          Variable<int>($EnhancedMessagesTable.$converterstatus.toSql(status));
    }
    map['is_sos'] = Variable<bool>(isSos);
    map['is_encrypted'] = Variable<bool>(isEncrypted);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || encryptionKey != null) {
      map['encryption_key'] = Variable<String>(encryptionKey);
    }
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deliveredTo != null) {
      map['delivered_to'] = Variable<String>(deliveredTo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EnhancedMessageCompanion toCompanion(bool nullToAbsent) {
    return EnhancedMessageCompanion(
      id: Value(id),
      messageId: Value(messageId),
      senderId: Value(senderId),
      receiverId: receiverId == null && nullToAbsent
          ? const Value.absent()
          : Value(receiverId),
      content: Value(content),
      timestamp: Value(timestamp),
      type: Value(type),
      status: Value(status),
      isSos: Value(isSos),
      isEncrypted: Value(isEncrypted),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      encryptionKey: encryptionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionKey),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deliveredTo: deliveredTo == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredTo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EnhancedMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnhancedMessage(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      receiverId: serializer.fromJson<String?>(json['receiverId']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      type: $EnhancedMessagesTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      status: $EnhancedMessagesTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      isSos: serializer.fromJson<bool>(json['isSos']),
      isEncrypted: serializer.fromJson<bool>(json['isEncrypted']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      encryptionKey: serializer.fromJson<String?>(json['encryptionKey']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deliveredTo: serializer.fromJson<String?>(json['deliveredTo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'senderId': serializer.toJson<String>(senderId),
      'receiverId': serializer.toJson<String?>(receiverId),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'type': serializer
          .toJson<int>($EnhancedMessagesTable.$convertertype.toJson(type)),
      'status': serializer
          .toJson<int>($EnhancedMessagesTable.$converterstatus.toJson(status)),
      'isSos': serializer.toJson<bool>(isSos),
      'isEncrypted': serializer.toJson<bool>(isEncrypted),
      'filePath': serializer.toJson<String?>(filePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'encryptionKey': serializer.toJson<String?>(encryptionKey),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deliveredTo': serializer.toJson<String?>(deliveredTo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EnhancedMessage copyWith(
          {int? id,
          String? messageId,
          String? senderId,
          Value<String?> receiverId = const Value.absent(),
          String? content,
          DateTime? timestamp,
          MessageType? type,
          MessageStatus? status,
          bool? isSos,
          bool? isEncrypted,
          Value<String?> filePath = const Value.absent(),
          Value<String?> thumbnailPath = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<String?> encryptionKey = const Value.absent(),
          Value<DateTime?> deliveredAt = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<String?> deliveredTo = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      EnhancedMessage(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        senderId: senderId ?? this.senderId,
        receiverId: receiverId.present ? receiverId.value : this.receiverId,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        type: type ?? this.type,
        status: status ?? this.status,
        isSos: isSos ?? this.isSos,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        filePath: filePath.present ? filePath.value : this.filePath,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        encryptionKey:
            encryptionKey.present ? encryptionKey.value : this.encryptionKey,
        deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        deliveredTo: deliveredTo.present ? deliveredTo.value : this.deliveredTo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EnhancedMessage copyWithCompanion(EnhancedMessageCompanion data) {
    return EnhancedMessage(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      receiverId:
          data.receiverId.present ? data.receiverId.value : this.receiverId,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      isSos: data.isSos.present ? data.isSos.value : this.isSos,
      isEncrypted:
          data.isEncrypted.present ? data.isEncrypted.value : this.isEncrypted,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      encryptionKey: data.encryptionKey.present
          ? data.encryptionKey.value
          : this.encryptionKey,
      deliveredAt:
          data.deliveredAt.present ? data.deliveredAt.value : this.deliveredAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deliveredTo:
          data.deliveredTo.present ? data.deliveredTo.value : this.deliveredTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnhancedMessage(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('receiverId: $receiverId, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('isSos: $isSos, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('encryptionKey: $encryptionKey, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deliveredTo: $deliveredTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      messageId,
      senderId,
      receiverId,
      content,
      timestamp,
      type,
      status,
      isSos,
      isEncrypted,
      filePath,
      thumbnailPath,
      latitude,
      longitude,
      encryptionKey,
      deliveredAt,
      syncedAt,
      deliveredTo,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnhancedMessage &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.senderId == this.senderId &&
          other.receiverId == this.receiverId &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.type == this.type &&
          other.status == this.status &&
          other.isSos == this.isSos &&
          other.isEncrypted == this.isEncrypted &&
          other.filePath == this.filePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.encryptionKey == this.encryptionKey &&
          other.deliveredAt == this.deliveredAt &&
          other.syncedAt == this.syncedAt &&
          other.deliveredTo == this.deliveredTo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EnhancedMessageCompanion extends UpdateCompanion<EnhancedMessage> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> senderId;
  final Value<String?> receiverId;
  final Value<String> content;
  final Value<DateTime> timestamp;
  final Value<MessageType> type;
  final Value<MessageStatus> status;
  final Value<bool> isSos;
  final Value<bool> isEncrypted;
  final Value<String?> filePath;
  final Value<String?> thumbnailPath;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> encryptionKey;
  final Value<DateTime?> deliveredAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> deliveredTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EnhancedMessageCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.receiverId = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.isSos = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.encryptionKey = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deliveredTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EnhancedMessageCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String senderId,
    this.receiverId = const Value.absent(),
    required String content,
    required DateTime timestamp,
    required MessageType type,
    required MessageStatus status,
    this.isSos = const Value.absent(),
    this.isEncrypted = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.encryptionKey = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deliveredTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : messageId = Value(messageId),
        senderId = Value(senderId),
        content = Value(content),
        timestamp = Value(timestamp),
        type = Value(type),
        status = Value(status);
  static Insertable<EnhancedMessage> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? senderId,
    Expression<String>? receiverId,
    Expression<String>? content,
    Expression<DateTime>? timestamp,
    Expression<int>? type,
    Expression<int>? status,
    Expression<bool>? isSos,
    Expression<bool>? isEncrypted,
    Expression<String>? filePath,
    Expression<String>? thumbnailPath,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? encryptionKey,
    Expression<DateTime>? deliveredAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? deliveredTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (senderId != null) 'sender_id': senderId,
      if (receiverId != null) 'receiver_id': receiverId,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (isSos != null) 'is_sos': isSos,
      if (isEncrypted != null) 'is_encrypted': isEncrypted,
      if (filePath != null) 'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (encryptionKey != null) 'encryption_key': encryptionKey,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deliveredTo != null) 'delivered_to': deliveredTo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EnhancedMessageCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<String>? senderId,
      Value<String?>? receiverId,
      Value<String>? content,
      Value<DateTime>? timestamp,
      Value<MessageType>? type,
      Value<MessageStatus>? status,
      Value<bool>? isSos,
      Value<bool>? isEncrypted,
      Value<String?>? filePath,
      Value<String?>? thumbnailPath,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<String?>? encryptionKey,
      Value<DateTime?>? deliveredAt,
      Value<DateTime?>? syncedAt,
      Value<String?>? deliveredTo,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return EnhancedMessageCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      isSos: isSos ?? this.isSos,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (receiverId.present) {
      map['receiver_id'] = Variable<String>(receiverId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $EnhancedMessagesTable.$convertertype.toSql(type.value));
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $EnhancedMessagesTable.$converterstatus.toSql(status.value));
    }
    if (isSos.present) {
      map['is_sos'] = Variable<bool>(isSos.value);
    }
    if (isEncrypted.present) {
      map['is_encrypted'] = Variable<bool>(isEncrypted.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (encryptionKey.present) {
      map['encryption_key'] = Variable<String>(encryptionKey.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deliveredTo.present) {
      map['delivered_to'] = Variable<String>(deliveredTo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnhancedMessageCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('receiverId: $receiverId, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('isSos: $isSos, ')
          ..write('isEncrypted: $isEncrypted, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('encryptionKey: $encryptionKey, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deliveredTo: $deliveredTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceTypeMeta =
      const VerificationMeta('deviceType');
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
      'device_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isOnlineMeta =
      const VerificationMeta('isOnline');
  @override
  late final GeneratedColumn<bool> isOnline = GeneratedColumn<bool>(
      'is_online', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_online" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
      'public_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, deviceType, lastSeen, isOnline, publicKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<Device> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_type')) {
      context.handle(
          _deviceTypeMeta,
          deviceType.isAcceptableOrUnknown(
              data['device_type']!, _deviceTypeMeta));
    } else if (isInserting) {
      context.missing(_deviceTypeMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('is_online')) {
      context.handle(_isOnlineMeta,
          isOnline.isAcceptableOrUnknown(data['is_online']!, _isOnlineMeta));
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      deviceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_type'])!,
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen'])!,
      isOnline: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_online'])!,
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key']),
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String id;
  final String name;
  final String deviceType;
  final DateTime lastSeen;
  final bool isOnline;
  final String? publicKey;
  const Device(
      {required this.id,
      required this.name,
      required this.deviceType,
      required this.lastSeen,
      required this.isOnline,
      this.publicKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['device_type'] = Variable<String>(deviceType);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['is_online'] = Variable<bool>(isOnline);
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    return map;
  }

  DeviceCompanion toCompanion(bool nullToAbsent) {
    return DeviceCompanion(
      id: Value(id),
      name: Value(name),
      deviceType: Value(deviceType),
      lastSeen: Value(lastSeen),
      isOnline: Value(isOnline),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
    );
  }

  factory Device.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deviceType: serializer.fromJson<String>(json['deviceType']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      isOnline: serializer.fromJson<bool>(json['isOnline']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'deviceType': serializer.toJson<String>(deviceType),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'isOnline': serializer.toJson<bool>(isOnline),
      'publicKey': serializer.toJson<String?>(publicKey),
    };
  }

  Device copyWith(
          {String? id,
          String? name,
          String? deviceType,
          DateTime? lastSeen,
          bool? isOnline,
          Value<String?> publicKey = const Value.absent()}) =>
      Device(
        id: id ?? this.id,
        name: name ?? this.name,
        deviceType: deviceType ?? this.deviceType,
        lastSeen: lastSeen ?? this.lastSeen,
        isOnline: isOnline ?? this.isOnline,
        publicKey: publicKey.present ? publicKey.value : this.publicKey,
      );
  Device copyWithCompanion(DeviceCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deviceType:
          data.deviceType.present ? data.deviceType.value : this.deviceType,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      isOnline: data.isOnline.present ? data.isOnline.value : this.isOnline,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceType: $deviceType, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('isOnline: $isOnline, ')
          ..write('publicKey: $publicKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, deviceType, lastSeen, isOnline, publicKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.name == this.name &&
          other.deviceType == this.deviceType &&
          other.lastSeen == this.lastSeen &&
          other.isOnline == this.isOnline &&
          other.publicKey == this.publicKey);
}

class DeviceCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> deviceType;
  final Value<DateTime> lastSeen;
  final Value<bool> isOnline;
  final Value<String?> publicKey;
  final Value<int> rowid;
  const DeviceCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.isOnline = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceCompanion.insert({
    required String id,
    required String name,
    required String deviceType,
    required DateTime lastSeen,
    this.isOnline = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        deviceType = Value(deviceType),
        lastSeen = Value(lastSeen);
  static Insertable<Device> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? deviceType,
    Expression<DateTime>? lastSeen,
    Expression<bool>? isOnline,
    Expression<String>? publicKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deviceType != null) 'device_type': deviceType,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (isOnline != null) 'is_online': isOnline,
      if (publicKey != null) 'public_key': publicKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? deviceType,
      Value<DateTime>? lastSeen,
      Value<bool>? isOnline,
      Value<String?>? publicKey,
      Value<int>? rowid}) {
    return DeviceCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      publicKey: publicKey ?? this.publicKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (isOnline.present) {
      map['is_online'] = Variable<bool>(isOnline.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceType: $deviceType, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('isOnline: $isOnline, ')
          ..write('publicKey: $publicKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageDeliveriesTable extends MessageDeliveries
    with TableInfo<$MessageDeliveriesTable, MessageDelivery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageDeliveriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deliveredAtMeta =
      const VerificationMeta('deliveredAt');
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
      'delivered_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _acknowledgedMeta =
      const VerificationMeta('acknowledged');
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
      'acknowledged', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("acknowledged" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, messageId, deviceId, deliveredAt, acknowledged];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_deliveries';
  @override
  VerificationContext validateIntegrity(Insertable<MessageDelivery> instance,
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
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
          _deliveredAtMeta,
          deliveredAt.isAcceptableOrUnknown(
              data['delivered_at']!, _deliveredAtMeta));
    } else if (isInserting) {
      context.missing(_deliveredAtMeta);
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
          _acknowledgedMeta,
          acknowledged.isAcceptableOrUnknown(
              data['acknowledged']!, _acknowledgedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageDelivery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageDelivery(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deliveredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}delivered_at'])!,
      acknowledged: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}acknowledged'])!,
    );
  }

  @override
  $MessageDeliveriesTable createAlias(String alias) {
    return $MessageDeliveriesTable(attachedDatabase, alias);
  }
}

class MessageDelivery extends DataClass implements Insertable<MessageDelivery> {
  final int id;
  final String messageId;
  final String deviceId;
  final DateTime deliveredAt;
  final bool acknowledged;
  const MessageDelivery(
      {required this.id,
      required this.messageId,
      required this.deviceId,
      required this.deliveredAt,
      required this.acknowledged});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['device_id'] = Variable<String>(deviceId);
    map['delivered_at'] = Variable<DateTime>(deliveredAt);
    map['acknowledged'] = Variable<bool>(acknowledged);
    return map;
  }

  MessageDeliveryCompanion toCompanion(bool nullToAbsent) {
    return MessageDeliveryCompanion(
      id: Value(id),
      messageId: Value(messageId),
      deviceId: Value(deviceId),
      deliveredAt: Value(deliveredAt),
      acknowledged: Value(acknowledged),
    );
  }

  factory MessageDelivery.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageDelivery(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deliveredAt: serializer.fromJson<DateTime>(json['deliveredAt']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'deviceId': serializer.toJson<String>(deviceId),
      'deliveredAt': serializer.toJson<DateTime>(deliveredAt),
      'acknowledged': serializer.toJson<bool>(acknowledged),
    };
  }

  MessageDelivery copyWith(
          {int? id,
          String? messageId,
          String? deviceId,
          DateTime? deliveredAt,
          bool? acknowledged}) =>
      MessageDelivery(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        deviceId: deviceId ?? this.deviceId,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        acknowledged: acknowledged ?? this.acknowledged,
      );
  MessageDelivery copyWithCompanion(MessageDeliveryCompanion data) {
    return MessageDelivery(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deliveredAt:
          data.deliveredAt.present ? data.deliveredAt.value : this.deliveredAt,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageDelivery(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('deviceId: $deviceId, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, messageId, deviceId, deliveredAt, acknowledged);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageDelivery &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.deviceId == this.deviceId &&
          other.deliveredAt == this.deliveredAt &&
          other.acknowledged == this.acknowledged);
}

class MessageDeliveryCompanion extends UpdateCompanion<MessageDelivery> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> deviceId;
  final Value<DateTime> deliveredAt;
  final Value<bool> acknowledged;
  const MessageDeliveryCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.acknowledged = const Value.absent(),
  });
  MessageDeliveryCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String deviceId,
    required DateTime deliveredAt,
    this.acknowledged = const Value.absent(),
  })  : messageId = Value(messageId),
        deviceId = Value(deviceId),
        deliveredAt = Value(deliveredAt);
  static Insertable<MessageDelivery> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? deviceId,
    Expression<DateTime>? deliveredAt,
    Expression<bool>? acknowledged,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (deviceId != null) 'device_id': deviceId,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (acknowledged != null) 'acknowledged': acknowledged,
    });
  }

  MessageDeliveryCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<String>? deviceId,
      Value<DateTime>? deliveredAt,
      Value<bool>? acknowledged}) {
    return MessageDeliveryCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      deviceId: deviceId ?? this.deviceId,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      acknowledged: acknowledged ?? this.acknowledged,
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
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageDeliveryCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('deviceId: $deviceId, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }
}

class $SosBroadcastsTable extends SosBroadcasts
    with TableInfo<$SosBroadcastsTable, SosBroadcast> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SosBroadcastsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sosIdMeta = const VerificationMeta('sosId');
  @override
  late final GeneratedColumn<String> sosId = GeneratedColumn<String>(
      'sos_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceNameMeta =
      const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
      'device_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _acknowledgedAtMeta =
      const VerificationMeta('acknowledgedAt');
  @override
  late final GeneratedColumn<DateTime> acknowledgedAt =
      GeneratedColumn<DateTime>('acknowledged_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sosId,
        deviceId,
        deviceName,
        message,
        latitude,
        longitude,
        timestamp,
        isActive,
        acknowledgedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sos_broadcasts';
  @override
  VerificationContext validateIntegrity(Insertable<SosBroadcast> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sos_id')) {
      context.handle(
          _sosIdMeta, sosId.isAcceptableOrUnknown(data['sos_id']!, _sosIdMeta));
    } else if (isInserting) {
      context.missing(_sosIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
          _deviceNameMeta,
          deviceName.isAcceptableOrUnknown(
              data['device_name']!, _deviceNameMeta));
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
          _acknowledgedAtMeta,
          acknowledgedAt.isAcceptableOrUnknown(
              data['acknowledged_at']!, _acknowledgedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SosBroadcast map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SosBroadcast(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sosId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sos_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_name'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      acknowledgedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}acknowledged_at']),
    );
  }

  @override
  $SosBroadcastsTable createAlias(String alias) {
    return $SosBroadcastsTable(attachedDatabase, alias);
  }
}

class SosBroadcast extends DataClass implements Insertable<SosBroadcast> {
  final int id;
  final String sosId;
  final String deviceId;
  final String deviceName;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final bool isActive;
  final DateTime? acknowledgedAt;
  const SosBroadcast(
      {required this.id,
      required this.sosId,
      required this.deviceId,
      required this.deviceName,
      required this.message,
      this.latitude,
      this.longitude,
      required this.timestamp,
      required this.isActive,
      this.acknowledgedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sos_id'] = Variable<String>(sosId);
    map['device_id'] = Variable<String>(deviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt);
    }
    return map;
  }

  SosBroadcastCompanion toCompanion(bool nullToAbsent) {
    return SosBroadcastCompanion(
      id: Value(id),
      sosId: Value(sosId),
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      message: Value(message),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      timestamp: Value(timestamp),
      isActive: Value(isActive),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
    );
  }

  factory SosBroadcast.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SosBroadcast(
      id: serializer.fromJson<int>(json['id']),
      sosId: serializer.fromJson<String>(json['sosId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      message: serializer.fromJson<String>(json['message']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      acknowledgedAt: serializer.fromJson<DateTime?>(json['acknowledgedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sosId': serializer.toJson<String>(sosId),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'message': serializer.toJson<String>(message),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isActive': serializer.toJson<bool>(isActive),
      'acknowledgedAt': serializer.toJson<DateTime?>(acknowledgedAt),
    };
  }

  SosBroadcast copyWith(
          {int? id,
          String? sosId,
          String? deviceId,
          String? deviceName,
          String? message,
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          DateTime? timestamp,
          bool? isActive,
          Value<DateTime?> acknowledgedAt = const Value.absent()}) =>
      SosBroadcast(
        id: id ?? this.id,
        sosId: sosId ?? this.sosId,
        deviceId: deviceId ?? this.deviceId,
        deviceName: deviceName ?? this.deviceName,
        message: message ?? this.message,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        timestamp: timestamp ?? this.timestamp,
        isActive: isActive ?? this.isActive,
        acknowledgedAt:
            acknowledgedAt.present ? acknowledgedAt.value : this.acknowledgedAt,
      );
  SosBroadcast copyWithCompanion(SosBroadcastCompanion data) {
    return SosBroadcast(
      id: data.id.present ? data.id.value : this.id,
      sosId: data.sosId.present ? data.sosId.value : this.sosId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName:
          data.deviceName.present ? data.deviceName.value : this.deviceName,
      message: data.message.present ? data.message.value : this.message,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SosBroadcast(')
          ..write('id: $id, ')
          ..write('sosId: $sosId, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('message: $message, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timestamp: $timestamp, ')
          ..write('isActive: $isActive, ')
          ..write('acknowledgedAt: $acknowledgedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sosId, deviceId, deviceName, message,
      latitude, longitude, timestamp, isActive, acknowledgedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SosBroadcast &&
          other.id == this.id &&
          other.sosId == this.sosId &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.message == this.message &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.timestamp == this.timestamp &&
          other.isActive == this.isActive &&
          other.acknowledgedAt == this.acknowledgedAt);
}

class SosBroadcastCompanion extends UpdateCompanion<SosBroadcast> {
  final Value<int> id;
  final Value<String> sosId;
  final Value<String> deviceId;
  final Value<String> deviceName;
  final Value<String> message;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> timestamp;
  final Value<bool> isActive;
  final Value<DateTime?> acknowledgedAt;
  const SosBroadcastCompanion({
    this.id = const Value.absent(),
    this.sosId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.message = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isActive = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
  });
  SosBroadcastCompanion.insert({
    this.id = const Value.absent(),
    required String sosId,
    required String deviceId,
    required String deviceName,
    required String message,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime timestamp,
    this.isActive = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
  })  : sosId = Value(sosId),
        deviceId = Value(deviceId),
        deviceName = Value(deviceName),
        message = Value(message),
        timestamp = Value(timestamp);
  static Insertable<SosBroadcast> custom({
    Expression<int>? id,
    Expression<String>? sosId,
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? message,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? timestamp,
    Expression<bool>? isActive,
    Expression<DateTime>? acknowledgedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sosId != null) 'sos_id': sosId,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (message != null) 'message': message,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timestamp != null) 'timestamp': timestamp,
      if (isActive != null) 'is_active': isActive,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
    });
  }

  SosBroadcastCompanion copyWith(
      {Value<int>? id,
      Value<String>? sosId,
      Value<String>? deviceId,
      Value<String>? deviceName,
      Value<String>? message,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<DateTime>? timestamp,
      Value<bool>? isActive,
      Value<DateTime?>? acknowledgedAt}) {
    return SosBroadcastCompanion(
      id: id ?? this.id,
      sosId: sosId ?? this.sosId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      message: message ?? this.message,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sosId.present) {
      map['sos_id'] = Variable<String>(sosId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<DateTime>(acknowledgedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SosBroadcastCompanion(')
          ..write('id: $id, ')
          ..write('sosId: $sosId, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('message: $message, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timestamp: $timestamp, ')
          ..write('isActive: $isActive, ')
          ..write('acknowledgedAt: $acknowledgedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$EnhancedAppDatabase extends GeneratedDatabase {
  _$EnhancedAppDatabase(QueryExecutor e) : super(e);
  $EnhancedAppDatabaseManager get managers => $EnhancedAppDatabaseManager(this);
  late final $EnhancedMessagesTable enhancedMessages =
      $EnhancedMessagesTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $MessageDeliveriesTable messageDeliveries =
      $MessageDeliveriesTable(this);
  late final $SosBroadcastsTable sosBroadcasts = $SosBroadcastsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [enhancedMessages, devices, messageDeliveries, sosBroadcasts];
}

typedef $$EnhancedMessagesTableCreateCompanionBuilder = EnhancedMessageCompanion
    Function({
  Value<int> id,
  required String messageId,
  required String senderId,
  Value<String?> receiverId,
  required String content,
  required DateTime timestamp,
  required MessageType type,
  required MessageStatus status,
  Value<bool> isSos,
  Value<bool> isEncrypted,
  Value<String?> filePath,
  Value<String?> thumbnailPath,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> encryptionKey,
  Value<DateTime?> deliveredAt,
  Value<DateTime?> syncedAt,
  Value<String?> deliveredTo,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$EnhancedMessagesTableUpdateCompanionBuilder = EnhancedMessageCompanion
    Function({
  Value<int> id,
  Value<String> messageId,
  Value<String> senderId,
  Value<String?> receiverId,
  Value<String> content,
  Value<DateTime> timestamp,
  Value<MessageType> type,
  Value<MessageStatus> status,
  Value<bool> isSos,
  Value<bool> isEncrypted,
  Value<String?> filePath,
  Value<String?> thumbnailPath,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> encryptionKey,
  Value<DateTime?> deliveredAt,
  Value<DateTime?> syncedAt,
  Value<String?> deliveredTo,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$EnhancedMessagesTableFilterComposer
    extends Composer<_$EnhancedAppDatabase, $EnhancedMessagesTable> {
  $$EnhancedMessagesTableFilterComposer({
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

  ColumnFilters<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiverId => $composableBuilder(
      column: $table.receiverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MessageType, MessageType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<MessageStatus, MessageStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isSos => $composableBuilder(
      column: $table.isSos, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get encryptionKey => $composableBuilder(
      column: $table.encryptionKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveredTo => $composableBuilder(
      column: $table.deliveredTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EnhancedMessagesTableOrderingComposer
    extends Composer<_$EnhancedAppDatabase, $EnhancedMessagesTable> {
  $$EnhancedMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get senderId => $composableBuilder(
      column: $table.senderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiverId => $composableBuilder(
      column: $table.receiverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSos => $composableBuilder(
      column: $table.isSos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptionKey => $composableBuilder(
      column: $table.encryptionKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveredTo => $composableBuilder(
      column: $table.deliveredTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EnhancedMessagesTableAnnotationComposer
    extends Composer<_$EnhancedAppDatabase, $EnhancedMessagesTable> {
  $$EnhancedMessagesTableAnnotationComposer({
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

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get receiverId => $composableBuilder(
      column: $table.receiverId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSos =>
      $composableBuilder(column: $table.isSos, builder: (column) => column);

  GeneratedColumn<bool> get isEncrypted => $composableBuilder(
      column: $table.isEncrypted, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get encryptionKey => $composableBuilder(
      column: $table.encryptionKey, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get deliveredTo => $composableBuilder(
      column: $table.deliveredTo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EnhancedMessagesTableTableManager extends RootTableManager<
    _$EnhancedAppDatabase,
    $EnhancedMessagesTable,
    EnhancedMessage,
    $$EnhancedMessagesTableFilterComposer,
    $$EnhancedMessagesTableOrderingComposer,
    $$EnhancedMessagesTableAnnotationComposer,
    $$EnhancedMessagesTableCreateCompanionBuilder,
    $$EnhancedMessagesTableUpdateCompanionBuilder,
    (
      EnhancedMessage,
      BaseReferences<_$EnhancedAppDatabase, $EnhancedMessagesTable,
          EnhancedMessage>
    ),
    EnhancedMessage,
    PrefetchHooks Function()> {
  $$EnhancedMessagesTableTableManager(
      _$EnhancedAppDatabase db, $EnhancedMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnhancedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnhancedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnhancedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> senderId = const Value.absent(),
            Value<String?> receiverId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<MessageType> type = const Value.absent(),
            Value<MessageStatus> status = const Value.absent(),
            Value<bool> isSos = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<String?> encryptionKey = const Value.absent(),
            Value<DateTime?> deliveredAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> deliveredTo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EnhancedMessageCompanion(
            id: id,
            messageId: messageId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            timestamp: timestamp,
            type: type,
            status: status,
            isSos: isSos,
            isEncrypted: isEncrypted,
            filePath: filePath,
            thumbnailPath: thumbnailPath,
            latitude: latitude,
            longitude: longitude,
            encryptionKey: encryptionKey,
            deliveredAt: deliveredAt,
            syncedAt: syncedAt,
            deliveredTo: deliveredTo,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            required String senderId,
            Value<String?> receiverId = const Value.absent(),
            required String content,
            required DateTime timestamp,
            required MessageType type,
            required MessageStatus status,
            Value<bool> isSos = const Value.absent(),
            Value<bool> isEncrypted = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<String?> encryptionKey = const Value.absent(),
            Value<DateTime?> deliveredAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> deliveredTo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EnhancedMessageCompanion.insert(
            id: id,
            messageId: messageId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            timestamp: timestamp,
            type: type,
            status: status,
            isSos: isSos,
            isEncrypted: isEncrypted,
            filePath: filePath,
            thumbnailPath: thumbnailPath,
            latitude: latitude,
            longitude: longitude,
            encryptionKey: encryptionKey,
            deliveredAt: deliveredAt,
            syncedAt: syncedAt,
            deliveredTo: deliveredTo,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EnhancedMessagesTableProcessedTableManager = ProcessedTableManager<
    _$EnhancedAppDatabase,
    $EnhancedMessagesTable,
    EnhancedMessage,
    $$EnhancedMessagesTableFilterComposer,
    $$EnhancedMessagesTableOrderingComposer,
    $$EnhancedMessagesTableAnnotationComposer,
    $$EnhancedMessagesTableCreateCompanionBuilder,
    $$EnhancedMessagesTableUpdateCompanionBuilder,
    (
      EnhancedMessage,
      BaseReferences<_$EnhancedAppDatabase, $EnhancedMessagesTable,
          EnhancedMessage>
    ),
    EnhancedMessage,
    PrefetchHooks Function()>;
typedef $$DevicesTableCreateCompanionBuilder = DeviceCompanion Function({
  required String id,
  required String name,
  required String deviceType,
  required DateTime lastSeen,
  Value<bool> isOnline,
  Value<String?> publicKey,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DeviceCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> deviceType,
  Value<DateTime> lastSeen,
  Value<bool> isOnline,
  Value<String?> publicKey,
  Value<int> rowid,
});

class $$DevicesTableFilterComposer
    extends Composer<_$EnhancedAppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceType => $composableBuilder(
      column: $table.deviceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOnline => $composableBuilder(
      column: $table.isOnline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnFilters(column));
}

class $$DevicesTableOrderingComposer
    extends Composer<_$EnhancedAppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceType => $composableBuilder(
      column: $table.deviceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOnline => $composableBuilder(
      column: $table.isOnline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnOrderings(column));
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$EnhancedAppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get deviceType => $composableBuilder(
      column: $table.deviceType, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<bool> get isOnline =>
      $composableBuilder(column: $table.isOnline, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);
}

class $$DevicesTableTableManager extends RootTableManager<
    _$EnhancedAppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, BaseReferences<_$EnhancedAppDatabase, $DevicesTable, Device>),
    Device,
    PrefetchHooks Function()> {
  $$DevicesTableTableManager(_$EnhancedAppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> deviceType = const Value.absent(),
            Value<DateTime> lastSeen = const Value.absent(),
            Value<bool> isOnline = const Value.absent(),
            Value<String?> publicKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeviceCompanion(
            id: id,
            name: name,
            deviceType: deviceType,
            lastSeen: lastSeen,
            isOnline: isOnline,
            publicKey: publicKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String deviceType,
            required DateTime lastSeen,
            Value<bool> isOnline = const Value.absent(),
            Value<String?> publicKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeviceCompanion.insert(
            id: id,
            name: name,
            deviceType: deviceType,
            lastSeen: lastSeen,
            isOnline: isOnline,
            publicKey: publicKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DevicesTableProcessedTableManager = ProcessedTableManager<
    _$EnhancedAppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, BaseReferences<_$EnhancedAppDatabase, $DevicesTable, Device>),
    Device,
    PrefetchHooks Function()>;
typedef $$MessageDeliveriesTableCreateCompanionBuilder
    = MessageDeliveryCompanion Function({
  Value<int> id,
  required String messageId,
  required String deviceId,
  required DateTime deliveredAt,
  Value<bool> acknowledged,
});
typedef $$MessageDeliveriesTableUpdateCompanionBuilder
    = MessageDeliveryCompanion Function({
  Value<int> id,
  Value<String> messageId,
  Value<String> deviceId,
  Value<DateTime> deliveredAt,
  Value<bool> acknowledged,
});

class $$MessageDeliveriesTableFilterComposer
    extends Composer<_$EnhancedAppDatabase, $MessageDeliveriesTable> {
  $$MessageDeliveriesTableFilterComposer({
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

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get acknowledged => $composableBuilder(
      column: $table.acknowledged, builder: (column) => ColumnFilters(column));
}

class $$MessageDeliveriesTableOrderingComposer
    extends Composer<_$EnhancedAppDatabase, $MessageDeliveriesTable> {
  $$MessageDeliveriesTableOrderingComposer({
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

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get acknowledged => $composableBuilder(
      column: $table.acknowledged,
      builder: (column) => ColumnOrderings(column));
}

class $$MessageDeliveriesTableAnnotationComposer
    extends Composer<_$EnhancedAppDatabase, $MessageDeliveriesTable> {
  $$MessageDeliveriesTableAnnotationComposer({
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

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => column);

  GeneratedColumn<bool> get acknowledged => $composableBuilder(
      column: $table.acknowledged, builder: (column) => column);
}

class $$MessageDeliveriesTableTableManager extends RootTableManager<
    _$EnhancedAppDatabase,
    $MessageDeliveriesTable,
    MessageDelivery,
    $$MessageDeliveriesTableFilterComposer,
    $$MessageDeliveriesTableOrderingComposer,
    $$MessageDeliveriesTableAnnotationComposer,
    $$MessageDeliveriesTableCreateCompanionBuilder,
    $$MessageDeliveriesTableUpdateCompanionBuilder,
    (
      MessageDelivery,
      BaseReferences<_$EnhancedAppDatabase, $MessageDeliveriesTable,
          MessageDelivery>
    ),
    MessageDelivery,
    PrefetchHooks Function()> {
  $$MessageDeliveriesTableTableManager(
      _$EnhancedAppDatabase db, $MessageDeliveriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageDeliveriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageDeliveriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageDeliveriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> deliveredAt = const Value.absent(),
            Value<bool> acknowledged = const Value.absent(),
          }) =>
              MessageDeliveryCompanion(
            id: id,
            messageId: messageId,
            deviceId: deviceId,
            deliveredAt: deliveredAt,
            acknowledged: acknowledged,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            required String deviceId,
            required DateTime deliveredAt,
            Value<bool> acknowledged = const Value.absent(),
          }) =>
              MessageDeliveryCompanion.insert(
            id: id,
            messageId: messageId,
            deviceId: deviceId,
            deliveredAt: deliveredAt,
            acknowledged: acknowledged,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessageDeliveriesTableProcessedTableManager = ProcessedTableManager<
    _$EnhancedAppDatabase,
    $MessageDeliveriesTable,
    MessageDelivery,
    $$MessageDeliveriesTableFilterComposer,
    $$MessageDeliveriesTableOrderingComposer,
    $$MessageDeliveriesTableAnnotationComposer,
    $$MessageDeliveriesTableCreateCompanionBuilder,
    $$MessageDeliveriesTableUpdateCompanionBuilder,
    (
      MessageDelivery,
      BaseReferences<_$EnhancedAppDatabase, $MessageDeliveriesTable,
          MessageDelivery>
    ),
    MessageDelivery,
    PrefetchHooks Function()>;
typedef $$SosBroadcastsTableCreateCompanionBuilder = SosBroadcastCompanion
    Function({
  Value<int> id,
  required String sosId,
  required String deviceId,
  required String deviceName,
  required String message,
  Value<double?> latitude,
  Value<double?> longitude,
  required DateTime timestamp,
  Value<bool> isActive,
  Value<DateTime?> acknowledgedAt,
});
typedef $$SosBroadcastsTableUpdateCompanionBuilder = SosBroadcastCompanion
    Function({
  Value<int> id,
  Value<String> sosId,
  Value<String> deviceId,
  Value<String> deviceName,
  Value<String> message,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<DateTime> timestamp,
  Value<bool> isActive,
  Value<DateTime?> acknowledgedAt,
});

class $$SosBroadcastsTableFilterComposer
    extends Composer<_$EnhancedAppDatabase, $SosBroadcastsTable> {
  $$SosBroadcastsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sosId => $composableBuilder(
      column: $table.sosId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt,
      builder: (column) => ColumnFilters(column));
}

class $$SosBroadcastsTableOrderingComposer
    extends Composer<_$EnhancedAppDatabase, $SosBroadcastsTable> {
  $$SosBroadcastsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sosId => $composableBuilder(
      column: $table.sosId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SosBroadcastsTableAnnotationComposer
    extends Composer<_$EnhancedAppDatabase, $SosBroadcastsTable> {
  $$SosBroadcastsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sosId =>
      $composableBuilder(column: $table.sosId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
      column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt, builder: (column) => column);
}

class $$SosBroadcastsTableTableManager extends RootTableManager<
    _$EnhancedAppDatabase,
    $SosBroadcastsTable,
    SosBroadcast,
    $$SosBroadcastsTableFilterComposer,
    $$SosBroadcastsTableOrderingComposer,
    $$SosBroadcastsTableAnnotationComposer,
    $$SosBroadcastsTableCreateCompanionBuilder,
    $$SosBroadcastsTableUpdateCompanionBuilder,
    (
      SosBroadcast,
      BaseReferences<_$EnhancedAppDatabase, $SosBroadcastsTable, SosBroadcast>
    ),
    SosBroadcast,
    PrefetchHooks Function()> {
  $$SosBroadcastsTableTableManager(
      _$EnhancedAppDatabase db, $SosBroadcastsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SosBroadcastsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SosBroadcastsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SosBroadcastsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> sosId = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> deviceName = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> acknowledgedAt = const Value.absent(),
          }) =>
              SosBroadcastCompanion(
            id: id,
            sosId: sosId,
            deviceId: deviceId,
            deviceName: deviceName,
            message: message,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            isActive: isActive,
            acknowledgedAt: acknowledgedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String sosId,
            required String deviceId,
            required String deviceName,
            required String message,
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            required DateTime timestamp,
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> acknowledgedAt = const Value.absent(),
          }) =>
              SosBroadcastCompanion.insert(
            id: id,
            sosId: sosId,
            deviceId: deviceId,
            deviceName: deviceName,
            message: message,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            isActive: isActive,
            acknowledgedAt: acknowledgedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SosBroadcastsTableProcessedTableManager = ProcessedTableManager<
    _$EnhancedAppDatabase,
    $SosBroadcastsTable,
    SosBroadcast,
    $$SosBroadcastsTableFilterComposer,
    $$SosBroadcastsTableOrderingComposer,
    $$SosBroadcastsTableAnnotationComposer,
    $$SosBroadcastsTableCreateCompanionBuilder,
    $$SosBroadcastsTableUpdateCompanionBuilder,
    (
      SosBroadcast,
      BaseReferences<_$EnhancedAppDatabase, $SosBroadcastsTable, SosBroadcast>
    ),
    SosBroadcast,
    PrefetchHooks Function()>;

class $EnhancedAppDatabaseManager {
  final _$EnhancedAppDatabase _db;
  $EnhancedAppDatabaseManager(this._db);
  $$EnhancedMessagesTableTableManager get enhancedMessages =>
      $$EnhancedMessagesTableTableManager(_db, _db.enhancedMessages);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$MessageDeliveriesTableTableManager get messageDeliveries =>
      $$MessageDeliveriesTableTableManager(_db, _db.messageDeliveries);
  $$SosBroadcastsTableTableManager get sosBroadcasts =>
      $$SosBroadcastsTableTableManager(_db, _db.sosBroadcasts);
}
