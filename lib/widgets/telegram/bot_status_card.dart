import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class BotStatusCard extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastUpdate;

  const BotStatusCard({
    super.key,
    required this.isOnline,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: LinearGradient(
            colors: isOnline 
                ? [AppTheme.successColor.withOpacity(0.1), AppTheme.successColor.withOpacity(0.05)]
                : [AppTheme.errorColor.withOpacity(0.1), AppTheme.errorColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? AppTheme.successColor : AppTheme.errorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? AppTheme.successColor : AppTheme.errorColor)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // Status Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOnline ? Icons.check_circle : Icons.error,
                        color: isOnline ? AppTheme.successColor : AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Bot Status: ${isOnline ? 'Online' : 'Offline'}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOnline ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXs),
                  
                  Text(
                    isOnline 
                        ? 'Bot is running and ready to handle requests'
                        : 'Bot is not responding. Check deployment status.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  if (lastUpdate != null) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Last checked: ${_formatDateTime(lastUpdate!)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Bot Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }
}