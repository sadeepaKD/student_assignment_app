import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/email_pool_provider.dart';
import '../../widgets/custom_button.dart';
import 'email_pool_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
      Provider.of<EmailPoolProvider>(context, listen: false).loadEmailPool();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Admin Dashboard'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: AppTheme.spacingS),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          authProvider.currentUser?.name.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Flexible(
                        child: Text(
                          authProvider.currentUser?.name ?? 'Admin',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome to your dashboard!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Manage students and ChatGPT account assignments with ease.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXl),
            
            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    
                    // Responsive grid for buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          // Desktop layout - 3 buttons in a row
                          return Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Manage Students',
                                  icon: Icons.people,
                                  onPressed: _navigateToStudentManagement,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: CustomButton(
                                  text: 'Email Pool',
                                  icon: Icons.email,
                                  onPressed: _navigateToEmailPool,
                                  style: CustomButtonStyle.secondary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: CustomButton(
                                  text: 'Assignments',
                                  icon: Icons.assignment,
                                  onPressed: _navigateToAssignments,
                                  style: CustomButtonStyle.secondary,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Mobile layout - stacked buttons
                          return Column(
                            children: [
                              CustomButton(
                                text: 'Manage Students',
                                icon: Icons.people,
                                onPressed: _navigateToStudentManagement,
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              CustomButton(
                                text: 'Email Pool',
                                icon: Icons.email,
                                onPressed: _navigateToEmailPool,
                                style: CustomButtonStyle.secondary,
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              CustomButton(
                                text: 'Assignments',
                                icon: Icons.assignment,
                                onPressed: _navigateToAssignments,
                                style: CustomButtonStyle.secondary,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingXl),
            
            // Students Overview with Email Pool Stats
            Consumer2<StudentProvider, EmailPoolProvider>(
              builder: (context, studentProvider, emailProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Overview',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    'Monitor students, email pool, and assignments',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            CustomButton(
                              text: 'Add Student',
                              icon: Icons.add,
                              onPressed: _navigateToStudentManagement,
                              fullWidth: false,
                              width: 140,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        if (studentProvider.isLoading || emailProvider.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingXl),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          // Enhanced stats cards with email pool data
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 700) {
                                return Row(
                                  children: _buildEnhancedStatCards(studentProvider, emailProvider),
                                );
                              } else {
                                return Column(
                                  children: _buildEnhancedStatCards(studentProvider, emailProvider)
                                      .map((widget) => Padding(
                                            padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                                            child: widget,
                                          ))
                                      .toList(),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: AppTheme.spacingXl),
            
            // Recent Activity (placeholder for future)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.timeline,
                              size: 48,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text(
                              'Activity tracking coming soon',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnhancedStatCards(StudentProvider studentProvider, EmailPoolProvider emailProvider) {
    return [
      Expanded(
        child: _buildStatCard(
          'Total Students',
          studentProvider.students.length.toString(),
          Icons.people,
          AppTheme.primaryColor,
        ),
      ),
      const SizedBox(width: AppTheme.spacingM),
      Expanded(
        child: _buildStatCard(
          'Active Students',
          studentProvider.students.where((s) => s.isActive).length.toString(),
          Icons.check_circle,
          AppTheme.successColor,
        ),
      ),
      const SizedBox(width: AppTheme.spacingM),
      Expanded(
        child: _buildStatCard(
          'Email Pool',
          emailProvider.emailPool.length.toString(),
          Icons.email,
          Colors.purple,
        ),
      ),
      const SizedBox(width: AppTheme.spacingM),
      Expanded(
        child: _buildStatCard(
          'Available Emails',
          emailProvider.emailPool.where((e) => e.isAvailable).length.toString(),
          Icons.mark_email_unread,
          Colors.orange,
        ),
      ),
    ];
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _navigateToStudentManagement() {
    context.go('/dashboard/students');
  }

  void _navigateToEmailPool() {
    context.go('/dashboard/email-pool');
  }

  void _navigateToAssignments() {
    context.go('/dashboard/assignments');
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Logout',
            style: CustomButtonStyle.danger,
            fullWidth: false,
            width: 80,
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}