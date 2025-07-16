import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/telegram_models.dart';
import '../../widgets/custom_button.dart';

class PendingRequestsSection extends StatelessWidget {
  final List<TelegramRequest> requests;
  final bool isLoading;
  final Function(TelegramRequest) onApprove;
  final Function(TelegramRequest, {String? reason}) onReject;

  const PendingRequestsSection({
    super.key,
    required this.requests,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(
          request: request,
          isLoading: isLoading,
          onApprove: () => onApprove(request),
          onReject: (reason) => onReject(request, reason: reason),
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
            Icons.check_circle_outline,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No Pending Requests',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'All approval requests have been processed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final TelegramRequest request;
  final bool isLoading;
  final VoidCallback onApprove;
  final Function(String?) onReject;

  const _RequestCard({
    required this.request,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 20,
                  child: Text(
                    _getInitial(request.telegramId),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingM),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telegram ID: ${request.telegramId}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        'WhatsApp: ${request.whatsappNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Time stamp
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    _formatTime(request.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Additional Info
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    'Requested ${DateFormat('MMM dd, yyyy at HH:mm').format(request.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    style: CustomButtonStyle.ghost,
                    icon: Icons.close,
                    onPressed: isLoading ? null : () => _showRejectDialog(context),
                    height: 36,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingS),
                
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'Approve',
                    style: CustomButtonStyle.primary,
                    icon: Icons.check,
                    onPressed: isLoading ? null : onApprove,
                    isLoading: isLoading,
                    height: 36,
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject this request?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Reject',
            style: CustomButtonStyle.danger,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onReject(reasonController.text.trim().isEmpty 
                  ? null 
                  : reasonController.text.trim());
            },
            fullWidth: false,
            width: 80,
            height: 32,
          ),
        ],
      ),
    );
  }
}