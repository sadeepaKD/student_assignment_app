import 'package:flutter/material.dart';
import '../../config/theme.dart';

class StatsOverview extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const StatsOverview({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout
        if (constraints.maxWidth > 800) {
          return Row(
            children: _buildStatCards(context).map((card) => 
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
                child: card,
              ))
            ).toList(),
          );
        } else if (constraints.maxWidth > 400) {
          final cards = _buildStatCards(context);
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        } else {
          // Stack vertically on mobile
          return Column(
            children: _buildStatCards(context).map((card) => 
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: card,
              )
            ).toList(),
          );
        }
      },
    );
  }

  List<Widget> _buildStatCards(BuildContext context) {
    return [
      _StatCard(
        title: 'Pending Requests',
        value: '${statistics['pendingRequests'] ?? 0}',
        icon: Icons.pending_actions,
        color: AppTheme.warningColor,
        subtitle: 'Awaiting approval',
      ),
      _StatCard(
        title: 'Approved Users',
        value: '${statistics['approvedUsers'] ?? 0}',
        icon: Icons.people,
        color: AppTheme.primaryColor,
        subtitle: 'Total registered',
      ),
      _StatCard(
        title: 'Active Users',
        value: '${statistics['activeUsers'] ?? 0}',
        icon: Icons.check_circle,
        color: AppTheme.successColor,
        subtitle: 'Currently active',
      ),
      _StatCard(
        title: 'Today\'s OTPs',
        value: '${statistics['todayOtpRequests'] ?? 0}',
        icon: Icons.security,
        color: Colors.purple,
        subtitle: 'Generated today',
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXs),
            
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}