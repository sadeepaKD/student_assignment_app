import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/telegram_bot_provider.dart';
import '../../widgets/custom_button.dart';

class TelegramBotScreen extends StatefulWidget {
  const TelegramBotScreen({super.key});

  @override
  State<TelegramBotScreen> createState() => _TelegramBotScreenState();
}

class _TelegramBotScreenState extends State<TelegramBotScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TelegramBotProvider>(context, listen: false).fetchAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot Management'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
        toolbarHeight: 56,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Approvals'),
            Tab(text: 'OTP Attempts'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, AppTheme.cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          child: Consumer<TelegramBotProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: AppTheme.errorColor),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text('Error: ${provider.error}'),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () => provider.fetchAllData(),
                        fullWidth: false,
                        width: 80,
                        height: 32,
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXs),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by Telegram ID or WhatsApp...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) => provider.setSearchQuery(value),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildApprovalsTab(provider),
                          _buildAttemptsTab(provider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalsTab(TelegramBotProvider provider) {
    if (provider.pendingRequests.isEmpty) {
      return const Center(child: Text('No pending approvals'));
    }
    return ListView.builder(
      itemCount: provider.pendingRequests.length,
      itemBuilder: (context, index) {
        final request = provider.pendingRequests[index];
        final telegramId = request['telegramId'] as String? ?? '';
        final firstChar = telegramId.isNotEmpty ? telegramId[0] : 'U'; // Safe access with fallback
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(firstChar, style: const TextStyle(color: Colors.white)),
            ),
            title: Text('Telegram ID: ${request['telegramId']}'),
            subtitle: Text('WhatsApp: ${request['whatsappNumber']}'),
            trailing: CustomButton(
              text: 'Approve',
              onPressed: () => provider.approveRequest(request['telegramId'], request['whatsappNumber']),
              fullWidth: false,
              width: 80,
              height: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttemptsTab(TelegramBotProvider provider) {
    if (provider.attempts.isEmpty) {
      return const Center(child: Text('No OTP attempts recorded'));
    }
    return ListView.builder(
      itemCount: provider.attempts.length,
      itemBuilder: (context, index) {
        final attempt = provider.attempts[index];
        final telegramId = attempt['telegramId'] as String? ?? '';
        final firstChar = telegramId.isNotEmpty ? telegramId[0] : 'U'; // Safe access with fallback
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(firstChar, style: const TextStyle(color: Colors.white)),
            ),
            title: Text('Telegram ID: ${attempt['telegramId']}'),
            subtitle: Text('${attempt['attemptCount']} attempts at ${attempt['timestamp']?.toDate()}'),
          ),
        );
      },
    );
  }
}