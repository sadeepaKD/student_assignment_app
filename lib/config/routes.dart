import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/email_pool_screen.dart';
import '../screens/dashboard/student_management_screen.dart';
import '../screens/dashboard/assignment_management_screen.dart';
import '../screens/telegram/telegram_dashboard.dart'; // Updated import

class AppRouter {
  static GoRouter get router => GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/email-pool',
            name: 'email-pool',
            builder: (context, state) => const EmailPoolScreen(),
          ),
          GoRoute(
            path: '/dashboard/students',
            name: 'students',
            builder: (context, state) => const StudentManagementScreen(),
          ),
          GoRoute(
            path: '/dashboard/assignments',
            name: 'assignments',
            builder: (context, state) => const AssignmentManagementScreen(),
          ),
          GoRoute(
            path: '/dashboard/telegram-bot',
            name: 'telegram-bot',
            builder: (context, state) => const TelegramDashboard(), // Updated to use new dashboard
          ),
        ],
      ),
    ],
  );
}

class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: child,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(_getPageTitle(context)),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        IconButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            }
          },
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Student Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Management Dashboard',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Students',
                  route: '/dashboard/students',
                  isSelected: currentRoute == '/dashboard/students',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.email,
                  title: 'Email Pool',
                  route: '/dashboard/email-pool',
                  isSelected: currentRoute == '/dashboard/email-pool',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assignment,
                  title: 'Assignments',
                  route: '/dashboard/assignments',
                  isSelected: currentRoute == '/dashboard/assignments',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.telegram,
                  title: 'Telegram Bot',
                  route: '/dashboard/telegram-bot',
                  isSelected: currentRoute == '/dashboard/telegram-bot',
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: '/dashboard/settings',
                  isSelected: false,
                  isDisabled: true, // Placeholder for future
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDisabled
            ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
            : isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled
              ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
              : isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      enabled: !isDisabled,
      onTap: isDisabled
          ? null
          : () {
              context.go(route);
              Navigator.of(context).pop(); // Close drawer
            },
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  String _getPageTitle(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    switch (currentRoute) {
      case '/dashboard':
        return 'Dashboard';
      case '/dashboard/students':
        return 'Students';
      case '/dashboard/email-pool':
        return 'Email Pool';
      case '/dashboard/assignments':
        return 'Assignments';
      case '/dashboard/telegram-bot':
        return 'Telegram Bot';
      default:
        return 'Student Admin';
    }
  }
}