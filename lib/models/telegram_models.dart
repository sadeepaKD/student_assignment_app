import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pending approval request from Telegram users
class TelegramRequest {
  final String id;
  final String telegramId;
  final String whatsappNumber;
  final DateTime createdAt;
  final String? telegramUsername;
  final RequestStatus status;

  TelegramRequest({
    required this.id,
    required this.telegramId,
    required this.whatsappNumber,
    required this.createdAt,
    this.telegramUsername,
    this.status = RequestStatus.pending,
  });

  factory TelegramRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle the actual data structure from your bot
    return TelegramRequest(
      id: doc.id,
      telegramId: data['telegramId']?.toString() ?? '',
      whatsappNumber: data['whatsappNumber']?.toString() ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // Use current time if createdAt doesn't exist
      telegramUsername: data['telegramUsername'],
      status: RequestStatus.pending,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'telegramId': telegramId,
      'whatsappNumber': whatsappNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'telegramUsername': telegramUsername,
    };
  }

  TelegramRequest copyWith({
    String? id,
    String? telegramId,
    String? whatsappNumber,
    DateTime? createdAt,
    String? telegramUsername,
    RequestStatus? status,
  }) {
    return TelegramRequest(
      id: id ?? this.id,
      telegramId: telegramId ?? this.telegramId,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      createdAt: createdAt ?? this.createdAt,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      status: status ?? this.status,
    );
  }
}

/// Represents an approved Telegram-WhatsApp link
class TelegramUser {
  final String id;
  final String telegramId;
  final String whatsappNumber;
  final DateTime approvedAt;
  final DateTime? lastActivity;
  final int otpRequestCount;
  final bool isActive;

  TelegramUser({
    required this.id,
    required this.telegramId,
    required this.whatsappNumber,
    required this.approvedAt,
    this.lastActivity,
    this.otpRequestCount = 0,
    this.isActive = true,
  });

  factory TelegramUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle the actual data structure from your bot
    return TelegramUser(
      id: doc.id,
      telegramId: data['telegramId']?.toString() ?? '',
      whatsappNumber: data['whatsappNumber']?.toString() ?? '',
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] as Timestamp).toDate()
          : data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(), // Use current time if no date available
      lastActivity: data['lastActivity'] != null 
          ? (data['lastActivity'] as Timestamp).toDate()
          : null,
      otpRequestCount: data['otpRequestCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'telegramId': telegramId,
      'whatsappNumber': whatsappNumber,
      'approvedAt': Timestamp.fromDate(approvedAt),
      'lastActivity': lastActivity != null 
          ? Timestamp.fromDate(lastActivity!)
          : null,
      'otpRequestCount': otpRequestCount,
      'isActive': isActive,
    };
  }
}

/// Bot activity/attempt tracking
class BotActivity {
  final String id;
  final String telegramId;
  final String whatsappNumber;
  final ActivityType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool success;

  BotActivity({
    required this.id,
    required this.telegramId,
    required this.whatsappNumber,
    required this.type,
    required this.timestamp,
    this.metadata,
    this.success = true,
  });

  factory BotActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BotActivity(
      id: doc.id,
      telegramId: data['telegramId'] ?? '',
      whatsappNumber: data['whatsappNumber'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.unknown,
      ),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'],
      success: data['success'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'telegramId': telegramId,
      'whatsappNumber': whatsappNumber,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'success': success,
    };
  }
}

/// Bot status tracking
class BotStatus {
  final bool isOnline;
  final DateTime lastSeen;
  final String version;
  final Map<String, dynamic> stats;

  BotStatus({
    required this.isOnline,
    required this.lastSeen,
    required this.version,
    required this.stats,
  });

  factory BotStatus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BotStatus(
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null 
          ? (data['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      version: data['version'] ?? 'Unknown',
      stats: data['stats'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'version': version,
      'stats': stats,
    };
  }
}

enum RequestStatus {
  pending,
  approved,
  rejected,
}

enum ActivityType {
  registration,
  otpRequest,
  photoUpload,
  approval,
  rejection,
  unknown,
}