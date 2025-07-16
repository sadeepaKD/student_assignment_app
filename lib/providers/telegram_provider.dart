import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/telegram_service.dart';
import '../models/telegram_models.dart';

class TelegramProvider extends ChangeNotifier {
  final TelegramService _telegramService = TelegramService();
  
  // State
  List<TelegramRequest> _pendingRequests = [];
  List<TelegramUser> _approvedUsers = [];
  List<BotActivity> _recentActivities = [];
  Map<String, dynamic> _statistics = {};
  
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _botOnline = false;
  
  // Streams
  StreamSubscription<List<TelegramRequest>>? _pendingRequestsSubscription;
  StreamSubscription<List<TelegramUser>>? _approvedUsersSubscription;
  StreamSubscription<List<BotActivity>>? _activitiesSubscription;
  Timer? _statsTimer;
  Timer? _botStatusTimer;

  // Getters
  List<TelegramRequest> get pendingRequests => _filterPendingRequests();
  List<TelegramUser> get approvedUsers => _filterApprovedUsers();
  List<BotActivity> get recentActivities => _recentActivities;
  Map<String, dynamic> get statistics => _statistics;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get botOnline => _botOnline;
  
  // Quick stats getters
  int get pendingCount => _pendingRequests.length;
  int get approvedCount => _approvedUsers.length;
  int get activeUsersCount => _approvedUsers.where((u) => u.isActive).length;

  TelegramProvider() {
    _initializeStreams();
    _startPeriodicUpdates();
  }

  /// Initialize real-time streams
  void _initializeStreams() {
    // Pending requests stream
    _pendingRequestsSubscription = _telegramService.getPendingRequestsStream().listen(
      (requests) {
        _pendingRequests = requests;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('⚠️ Pending requests stream error: $error');
        _pendingRequests = [];
        notifyListeners();
      },
    );

    // Approved users stream
    _approvedUsersSubscription = _telegramService.getApprovedUsersStream().listen(
      (users) {
        _approvedUsers = users;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('⚠️ Approved users stream error: $error');
        _approvedUsers = [];
        notifyListeners();
      },
    );

    // Recent activities stream (safe fallback)
    _activitiesSubscription = _telegramService.getBotActivitiesStream(limit: 50).listen(
      (activities) {
        _recentActivities = activities;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('⚠️ Activities stream error: $error');
        _recentActivities = [];
        notifyListeners();
      },
    );
  }

  /// Start periodic updates for stats and bot status
  void _startPeriodicUpdates() {
    // Update statistics every 30 seconds
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateStatistics();
    });

    // Check bot status every 60 seconds
    _botStatusTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkBotStatus();
    });

    // Initial updates
    _updateStatistics();
    _checkBotStatus();
  }

  /// Update search query and filter results
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Filter pending requests based on search query
  List<TelegramRequest> _filterPendingRequests() {
    if (_searchQuery.isEmpty) return _pendingRequests;
    
    return _pendingRequests.where((request) =>
        request.telegramId.toLowerCase().contains(_searchQuery) ||
        request.whatsappNumber.contains(_searchQuery)
    ).toList();
  }

  /// Filter approved users based on search query
  List<TelegramUser> _filterApprovedUsers() {
    if (_searchQuery.isEmpty) return _approvedUsers;
    
    return _approvedUsers.where((user) =>
        user.telegramId.toLowerCase().contains(_searchQuery) ||
        user.whatsappNumber.contains(_searchQuery)
    ).toList();
  }

  /// Approve a pending request
  Future<void> approveRequest(TelegramRequest request) async {
    try {
      _setLoading(true);
      await _telegramService.approveRequest(request);
      _clearError();
    } catch (e) {
      _setError('Failed to approve request: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Reject a pending request
  Future<void> rejectRequest(TelegramRequest request, {String? reason}) async {
    try {
      _setLoading(true);
      await _telegramService.rejectRequest(request, reason: reason);
      _clearError();
    } catch (e) {
      _setError('Failed to reject request: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete/remove user connection
  Future<void> deleteUserConnection(TelegramUser user) async {
    try {
      _setLoading(true);
      await _telegramService.deleteUserConnection(user);
      _clearError();
    } catch (e) {
      _setError('Failed to delete user connection: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data manually
  Future<void> refreshData() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Refresh statistics and bot status
      await Future.wait([
        _updateStatistics(),
        _checkBotStatus(),
      ]);
      
    } catch (e) {
      _setError('Failed to refresh data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update statistics
  Future<void> _updateStatistics() async {
    try {
      _statistics = await _telegramService.getBotStatistics();
      notifyListeners();
    } catch (e) {
      print('❌ Failed to update statistics: $e');
      // Don't set error for background updates
    }
  }

  /// Check bot online status
  Future<void> _checkBotStatus() async {
    try {
      _botOnline = await _telegramService.checkBotStatus();
      notifyListeners();
    } catch (e) {
      _botOnline = false;
      notifyListeners();
      print('❌ Failed to check bot status: $e');
    }
  }

  /// Get activities for a specific user
  List<BotActivity> getActivitiesForUser(String telegramId) {
    return _recentActivities
        .where((activity) => activity.telegramId == telegramId)
        .toList();
  }

  /// Get today's activities count
  int getTodayActivitiesCount() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return _recentActivities
        .where((activity) => activity.timestamp.isAfter(todayStart))
        .length;
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel all subscriptions and timers
    _pendingRequestsSubscription?.cancel();
    _approvedUsersSubscription?.cancel();
    _activitiesSubscription?.cancel();
    _statsTimer?.cancel();
    _botStatusTimer?.cancel();
    super.dispose();
  }
}