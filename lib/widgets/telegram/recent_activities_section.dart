import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/telegram_models.dart';

class RecentActivitiesSection extends StatelessWidget {
  final List<BotActivity> activities;
  final bool isLoading;

  const RecentActivitiesSection({
    super.key,
    required this.activities,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _ActivityCard(activity: activity);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No Recent Activities',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Bot activities will appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final BotActivity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityInfo = _getActivityInfo(activity.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // Activity Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: activityInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                activityInfo.icon,
                color: activityInfo.color,
                size: 20,
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // Activity Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityInfo.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Telegram ID: ${activity.telegramId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (activity.whatsappNumber.isNotEmpty) ...[
                    Text(
                      'WhatsApp: ${activity.whatsappNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      _formatMetadata(activity.metadata!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Timestamp and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(activity.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: activity.success 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Text(
                    activity.success ? 'Success' : 'Failed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: activity.success ? AppTheme.successColor : AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ActivityInfo _getActivityInfo(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return ActivityInfo(
          title: 'User Registration',
          icon: Icons.person_add,
          color: AppTheme.primaryColor,
        );
      case ActivityType.otpRequest:
        return ActivityInfo(
          title: 'OTP Request',
          icon: Icons.security,
          color: Colors.purple,
        );
      case ActivityType.photoUpload:
        return ActivityInfo(
          title: 'Screenshot Upload',
          icon: Icons.photo_camera,
          color: Colors.orange,
        );
      case ActivityType.approval:
        return ActivityInfo(
          title: 'Request Approved',
          icon: Icons.check_circle,
          color: AppTheme.successColor,
        );
      case ActivityType.rejection:
        return ActivityInfo(
          title: 'Request Rejected',
          icon: Icons.cancel,
          color: AppTheme.errorColor,
        );
      case ActivityType.unknown:
      default:
        return ActivityInfo(
          title: 'Bot Activity',
          icon: Icons.smart_toy,
          color: AppTheme.textSecondary,
        );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();
    metadata.forEach((key, value) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('$key: $value');
    });
    return buffer.toString();
  }
}

class ActivityInfo {
  final String title;
  final IconData icon;
  final Color color;

  ActivityInfo({
    required this.title,
    required this.icon,
    required this.color,
  });
}