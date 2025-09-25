enum MessageType {
  text,
  image,
  video,
  location,
  sos,
  file,
}

enum MessageStatus {
  sending,     // กำลังส่ง
  sent,        // ส่งแล้ว
  delivered,   // ส่งถึงแล้ว
  read,        // อ่านแล้ว
  failed,      // ส่งไม่สำเร็จ
  synced,      // ซิงก์ขึ้น cloud แล้ว
}

enum DeviceRole {
  sosUser,     // ผู้ขอความช่วยเหลือ
  rescuer,     // หน่วยกู้ภัย
  normal,      // ผู้ใช้ทั่วไป
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? filePath;
  final double? latitude;
  final double? longitude;
  final bool isEmergency;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.metadata,
    this.filePath,
    this.latitude,
    this.longitude,
    this.isEmergency = false,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? filePath,
    double? latitude,
    double? longitude,
    bool? isEmergency,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      filePath: filePath ?? this.filePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata,
      'filePath': filePath,
      'latitude': latitude,
      'longitude': longitude,
      'isEmergency': isEmergency,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      receiverId: json['receiverId'],
      content: json['content'],
      type: MessageType.values[json['type']],
      status: MessageStatus.values[json['status']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      metadata: json['metadata'],
      filePath: json['filePath'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isEmergency: json['isEmergency'] ?? false,
    );
  }
}

class NearbyDevice {
  final String id;
  final String name;
  final DeviceRole role;
  final bool isSOSActive;
  final bool isRescuerActive;
  final DateTime lastSeen;
  final double? latitude;
  final double? longitude;
  final int signalStrength;
  final bool isConnected;
  final String connectionType; // 'bluetooth', 'wifi_direct', 'nearby'

  NearbyDevice({
    required this.id,
    required this.name,
    required this.role,
    required this.isSOSActive,
    required this.isRescuerActive,
    required this.lastSeen,
    this.latitude,
    this.longitude,
    required this.signalStrength,
    required this.isConnected,
    required this.connectionType,
  });

  NearbyDevice copyWith({
    String? id,
    String? name,
    DeviceRole? role,
    bool? isSOSActive,
    bool? isRescuerActive,
    DateTime? lastSeen,
    double? latitude,
    double? longitude,
    int? signalStrength,
    bool? isConnected,
    String? connectionType,
  }) {
    return NearbyDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isSOSActive: isSOSActive ?? this.isSOSActive,
      isRescuerActive: isRescuerActive ?? this.isRescuerActive,
      lastSeen: lastSeen ?? this.lastSeen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      signalStrength: signalStrength ?? this.signalStrength,
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.index,
      'isSOSActive': isSOSActive,
      'isRescuerActive': isRescuerActive,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'signalStrength': signalStrength,
      'isConnected': isConnected,
      'connectionType': connectionType,
    };
  }

  factory NearbyDevice.fromJson(Map<String, dynamic> json) {
    return NearbyDevice(
      id: json['id'],
      name: json['name'],
      role: DeviceRole.values[json['role']],
      isSOSActive: json['isSOSActive'],
      isRescuerActive: json['isRescuerActive'],
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      signalStrength: json['signalStrength'],
      isConnected: json['isConnected'],
      connectionType: json['connectionType'],
    );
  }
}