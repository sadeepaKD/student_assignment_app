import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/telegram_provider.dart';
import '../../widgets/telegram/bot_status_card.dart';
import '../../widgets/telegram/stats_overview.dart';
import '../../widgets/telegram/pending_requests_section.dart';
import '../../widgets/telegram/approved_users_section.dart';
import '../../widgets/telegram/recent_activities_section.dart';

class TelegramDashboard extends StatefulWidget {
  const TelegramDashboard({super.key});

  @override
  State<TelegramDashboard> createState() => _TelegramDashboardState();
}

class _TelegramDashboardState extends State<TelegramDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize provider if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TelegramProvider>();
      provider.refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot Management'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        toolbarHeight: 56,
        actions: [
          Consumer<TelegramProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : provider.refreshData,
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Telegram ID or WhatsApp number...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              context.read<TelegramProvider>().clearSearch();
                            },
                            icon: const Icon(Icons.clear, size: 20),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    context.read<TelegramProvider>().setSearchQuery(value);
                  },
                ),
              ),
              
              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                tabs: [
                  Consumer<TelegramProvider>(
                    builder: (context, provider, child) {
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Approvals'),
                            if (provider.pendingCount > 0) ...[
                              const SizedBox(width: AppTheme.spacingXs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${provider.pendingCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const Tab(text: 'Users'),
                  const Tab(text: 'Activity'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<TelegramProvider>(
        builder: (context, provider, child) {
          if (provider.error != null) {
            return _buildErrorState(provider);
          }
          
          return Column(
            children: [
              // Status and Stats Overview
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    BotStatusCard(
                      isOnline: provider.botOnline,
                      lastUpdate: provider.statistics['lastUpdated'],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    StatsOverview(statistics: provider.statistics),
                  ],
                ),
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PendingRequestsSection(
                      requests: provider.pendingRequests,
                      isLoading: provider.isLoading,
                      onApprove: provider.approveRequest,
                      onReject: provider.rejectRequest,
                    ),
                    ApprovedUsersSection(
                      users: provider.approvedUsers,
                      isLoading: provider.isLoading,
                      onDeleteConnection: provider.deleteUserConnection,
                    ),
                    RecentActivitiesSection(
                      activities: provider.recentActivities,
                      isLoading: provider.isLoading,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(TelegramProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Text(
              provider.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: () {
              provider.clearError();
              provider.refreshData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}