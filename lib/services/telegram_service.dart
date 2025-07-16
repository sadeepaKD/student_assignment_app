import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/telegram_models.dart';

class TelegramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Your bot token - TODO: Move to secure config
  static const String _botToken = '7874539745:AAFN4ND227SwXtl3TAmB-fyAMdo9toPmXw0';
  static const String _baseUrl = 'https://api.telegram.org/bot$_botToken';

  // Collection references
  CollectionReference get _pendingLinks => _firestore.collection('pending_links');
  CollectionReference get _approvedLinks => _firestore.collection('links');
  CollectionReference get _botActivities => _firestore.collection('bot_activities');
  
  /// Get real-time stream of pending approval requests
  Stream<List<TelegramRequest>> getPendingRequestsStream() {
    return _pendingLinks
        .snapshots()
        .map((snapshot) {
          print('📋 Pending requests: ${snapshot.docs.length} documents');
          final requests = <TelegramRequest>[];
          
          for (var doc in snapshot.docs) {
            try {
              print('📋 Processing doc ${doc.id}: ${doc.data()}');
              final request = TelegramRequest.fromFirestore(doc);
              requests.add(request);
              print('✅ Successfully parsed request: ${request.telegramId} - ${request.whatsappNumber}');
            } catch (e) {
              print('❌ Error parsing document ${doc.id}: $e');
            }
          }
          
          print('📋 Final parsed requests: ${requests.length}');
          return requests;
        });
  }

  /// Get real-time stream of approved users
  Stream<List<TelegramUser>> getApprovedUsersStream() {
    return _approvedLinks
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TelegramUser.fromFirestore(doc))
            .toList());
  }

  /// Get real-time stream of bot activities/attempts
  Stream<List<BotActivity>> getBotActivitiesStream({int? limit}) {
    try {
      Query query = _botActivities.orderBy('timestamp', descending: true);
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => BotActivity.fromFirestore(doc))
          .toList());
    } catch (e) {
      // If collection doesn't exist or needs index, return empty stream
      print('⚠️ Bot activities stream not available: $e');
      return Stream.value(<BotActivity>[]);
    }
  }

  /// Approve a pending request
  Future<void> approveRequest(TelegramRequest request) async {
    try {
      final batch = _firestore.batch();
      
      // Add to approved links
      final approvedData = TelegramUser(
        id: '', // Will be set by Firestore
        telegramId: request.telegramId,
        whatsappNumber: request.whatsappNumber,
        approvedAt: DateTime.now(),
      );
      
      final approvedRef = _approvedLinks.doc();
      batch.set(approvedRef, approvedData.toFirestore());
      
      // Remove from pending
      batch.delete(_pendingLinks.doc(request.id));
      
      // Log activity
      final activityData = BotActivity(
        id: '',
        telegramId: request.telegramId,
        whatsappNumber: request.whatsappNumber,
        type: ActivityType.approval,
        timestamp: DateTime.now(),
        metadata: {'approvedBy': 'admin'},
      );
      
      final activityRef = _botActivities.doc();
      batch.set(activityRef, activityData.toFirestore());
      
      await batch.commit();
      
      // Send Telegram notification
      await _sendTelegramMessage(
        request.telegramId,
        '✅ You\'ve been approved! Please send your ChatGPT OTP screenshot to get your OTPs.',
      );
      
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  /// Reject a pending request
  Future<void> rejectRequest(TelegramRequest request, {String? reason}) async {
    try {
      final batch = _firestore.batch();
      
      // Remove from pending
      batch.delete(_pendingLinks.doc(request.id));
      
      // Log activity
      final activityData = BotActivity(
        id: '',
        telegramId: request.telegramId,
        whatsappNumber: request.whatsappNumber,
        type: ActivityType.rejection,
        timestamp: DateTime.now(),
        metadata: {
          'rejectedBy': 'admin',
          'reason': reason ?? 'No reason provided',
        },
        success: false,
      );
      
      final activityRef = _botActivities.doc();
      batch.set(activityRef, activityData.toFirestore());
      
      await batch.commit();
      
      // Send Telegram notification
      final message = reason != null 
          ? '❌ Your request was rejected. Reason: $reason'
          : '❌ Your request was rejected. Please contact support if you believe this is an error.';
          
      await _sendTelegramMessage(request.telegramId, message);
      
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  /// Delete/remove a user connection
  Future<void> deleteUserConnection(TelegramUser user) async {
    try {
      await _approvedLinks.doc(user.id).delete();
      
      // Send notification to user
      await _sendTelegramMessage(
        user.telegramId,
        '⚠️ Your access has been revoked by admin. Please contact support if you believe this is an error.',
      );
      
    } catch (e) {
      throw Exception('Failed to delete user connection: $e');
    }
  }

  /// Get statistics for dashboard
  Future<Map<String, dynamic>> getBotStatistics() async {
    try {
      // Get basic counts from existing collections
      final pendingCount = await _pendingLinks.get().then((s) => s.docs.length);
      final approvedCount = await _approvedLinks.get().then((s) => s.docs.length);
      
      // Count active users (all approved users are considered active)
      int activeUsersCount = approvedCount;
      
      // Get today's OTP usage from used_hashes collection
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      int todayOtpRequests = 0;
      try {
        // Count used hashes from today (each hash = one OTP request)
        final todayHashes = await _firestore
            .collection('used_hashes')
            .where('used', isEqualTo: true)
            .get();
        
        // Filter for today's requests (if timestamp exists)
        todayOtpRequests = todayHashes.docs.length; // For now, show total
        
        print('📊 Statistics: pending=$pendingCount, approved=$approvedCount, otpRequests=$todayOtpRequests');
      } catch (e) {
        print('⚠️ Could not get OTP statistics: $e');
        todayOtpRequests = 0;
      }
      
      return {
        'pendingRequests': pendingCount,
        'approvedUsers': approvedCount,
        'activeUsers': activeUsersCount,
        'todayActivities': todayOtpRequests, // Show OTP requests as activities
        'todayOtpRequests': todayOtpRequests,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Send message via Telegram Bot API
  Future<void> _sendTelegramMessage(String chatId, String message) async {
    try {
      final url = Uri.parse('$_baseUrl/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );
      
      if (response.statusCode != 200) {
        print('❌ Failed to send Telegram message: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending Telegram message: $e');
      // Don't throw - we don't want to fail the operation just because notification failed
    }
  }

  /// Check if bot is online (simplified version)
  Future<bool> checkBotStatus() async {
    try {
      final url = Uri.parse('$_baseUrl/getMe');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Search functionality
  Stream<List<TelegramRequest>> searchPendingRequests(String query) {
    if (query.isEmpty) return getPendingRequestsStream();
    
    return getPendingRequestsStream().map((requests) => 
        requests.where((request) =>
            request.telegramId.toLowerCase().contains(query.toLowerCase()) ||
            request.whatsappNumber.contains(query)
        ).toList()
    );
  }

  Stream<List<TelegramUser>> searchApprovedUsers(String query) {
    if (query.isEmpty) return getApprovedUsersStream();
    
    return getApprovedUsersStream().map((users) => 
        users.where((user) =>
            user.telegramId.toLowerCase().contains(query.toLowerCase()) ||
            user.whatsappNumber.contains(query)
        ).toList()
    );
  }
}