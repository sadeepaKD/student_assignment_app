// Create a new file: lib/utils/performance_monitor.dart

import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _durations = {};

  /// Start timing an operation
  static void startTimer(String operationName) {
    _startTimes[operationName] = DateTime.now();
    if (kDebugMode) {
      print('🚀 Started: $operationName');
    }
  }

  /// End timing an operation and log the duration
  static Duration endTimer(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      if (kDebugMode) {
        print('⚠️ Timer not found for: $operationName');
      }
      return Duration.zero;
    }

    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operationName);

    // Store duration for analytics
    _durations.putIfAbsent(operationName, () => []);
    _durations[operationName]!.add(duration);

    // Log with color coding based on duration
    if (kDebugMode) {
      final milliseconds = duration.inMilliseconds;
      String emoji;
      if (milliseconds < 100) {
        emoji = '🟢'; // Fast - under 100ms
      } else if (milliseconds < 500) {
        emoji = '🟡'; // Moderate - 100-500ms
      } else if (milliseconds < 1000) {
        emoji = '🟠'; // Slow - 500ms-1s
      } else {
        emoji = '🔴'; // Very slow - over 1s
      }
      
      print('$emoji Completed: $operationName in ${milliseconds}ms');
    }

    return duration;
  }

  /// Get average duration for an operation
  static Duration getAverageDuration(String operationName) {
    final durations = _durations[operationName];
    if (durations == null || durations.isEmpty) {
      return Duration.zero;
    }

    final totalMs = durations
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: (totalMs / durations.length).round());
  }

  /// Get performance summary
  static void printPerformanceSummary() {
    if (!kDebugMode) return;

    print('\n📊 PERFORMANCE SUMMARY');
    print('=' * 50);

    for (final operation in _durations.keys) {
      final durations = _durations[operation]!;
      final avg = getAverageDuration(operation);
      final min = durations.reduce((a, b) => a.inMilliseconds < b.inMilliseconds ? a : b);
      final max = durations.reduce((a, b) => a.inMilliseconds > b.inMilliseconds ? a : b);

      print('📈 $operation:');
      print('   Calls: ${durations.length}');
      print('   Average: ${avg.inMilliseconds}ms');
      print('   Min: ${min.inMilliseconds}ms');
      print('   Max: ${max.inMilliseconds}ms');
      print('');
    }

    print('=' * 50);
  }

  /// Clear all performance data
  static void clear() {
    _startTimes.clear();
    _durations.clear();
  }

  /// Wrap a future with performance monitoring
  static Future<T> monitorAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }

  /// Wrap a synchronous operation with performance monitoring
  static T monitor<T>(
    String operationName,
    T Function() operation,
  ) {
    startTimer(operationName);
    try {
      final result = operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }
}