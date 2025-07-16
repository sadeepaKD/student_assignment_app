import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/telegram_models.dart';

class ApprovedUsersSection extends StatelessWidget {
  final List<TelegramUser> users;
  final bool isLoading;
  final Function(TelegramUser) onDeleteConnection;

  const ApprovedUsersSection({
    super.key,
    required this.users,
    required this.isLoading,
    required this.onDeleteConnection,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserCard(
          user: user,
          isLoading: isLoading,
          onDeleteConnection: () => onDeleteConnection(user),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No Approved Users',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Approved users will appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final TelegramUser user;
  final bool isLoading;
  final VoidCallback onDeleteConnection;

  const _UserCard({
    required this.user,
    required this.isLoading,
    required this.onDeleteConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: user.isActive ? AppTheme.successColor : AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // User Avatar
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 20,
              child: Text(
                _getInitial(user.telegramId),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telegram ID: ${user.telegramId}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'WhatsApp: ${user.whatsappNumber}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        'Approved ${_formatDate(user.approvedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    'Connected',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                Text(
                  '${user.otpRequestCount} OTP requests',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingS),
                
                // Action Button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmDialog(context, user);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 18,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Delete Connection',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitial(String telegramId) {
    if (telegramId.isEmpty) return 'U';
    return telegramId[0].toUpperCase();
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, TelegramUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this bot connection?'),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telegram ID: ${user.telegramId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('WhatsApp: ${user.whatsappNumber}'),
                  Text('Connected: ${_formatDate(user.approvedAt)}'),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The user will lose access to the bot.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDeleteConnection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}