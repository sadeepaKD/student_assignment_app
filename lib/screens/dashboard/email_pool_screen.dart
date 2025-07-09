import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../config/theme.dart';
import '../../providers/email_pool_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/student.dart';

class EmailPoolScreen extends StatefulWidget {
  const EmailPoolScreen({super.key});

  @override
  State<EmailPoolScreen> createState() => _EmailPoolScreenState();
}

class _EmailPoolScreenState extends State<EmailPoolScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmailPoolProvider>(context, listen: false).loadEmailPool();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Pool Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomButton(
              text: 'Add Email',
              icon: Icons.add,
              onPressed: _showAddEmailDialog,
              fullWidth: false,
              width: 120,
            ),
          ),
        ],
      ),
      body: Consumer<EmailPoolProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emailProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                    child: Text(
                      'Error: ${emailProvider.error}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () => emailProvider.loadEmailPool(),
                    fullWidth: false,
                    width: 100,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                _buildStatsCards(emailProvider),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Email Pool Table
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ChatGPT Email Pool',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            'Manage your ChatGPT email accounts and TOTP secrets',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          
                          // Table
                          Expanded(
                            child: _buildEmailTable(emailProvider.emailPool),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(EmailPoolProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Emails',
                  provider.totalEmails.toString(),
                  Icons.email,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Available',
                  provider.availableEmailsCount.toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Assigned',
                  provider.assignedEmailsCount.toString(),
                  Icons.assignment,
                  AppTheme.warningColor,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatCard(
                'Total Emails',
                provider.totalEmails.toString(),
                Icons.email,
                AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Available',
                      provider.availableEmailsCount.toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      'Assigned',
                      provider.assignedEmailsCount.toString(),
                      Icons.assignment,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppTheme.spacingS),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTable(List<EmailPool> emails) {
    if (emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No emails in pool',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Add ChatGPT email accounts to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            CustomButton(
              text: 'Add First Email',
              icon: Icons.add,
              onPressed: _showAddEmailDialog,
              fullWidth: false,
              width: 150,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return _buildEmailCard(email);
      },
    );
  }

  Widget _buildEmailCard(EmailPool email) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: email.isAvailable ? AppTheme.successColor : AppTheme.warningColor,
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // Email Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Text(
                        'TOTP: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '••••••••••••••••',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () => _copyTotpSecret(email.totpSecret),
                        tooltip: 'Copy TOTP Secret',
                      ),
                    ],
                  ),
                  Text(
                    email.isAvailable ? 'Available' : 'Assigned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: email.isAvailable ? AppTheme.successColor : AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleEmailAction(value, email),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_totp',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: AppTheme.spacingS),
                      Text('View TOTP'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: AppTheme.spacingS),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                      SizedBox(width: AppTheme.spacingS),
                      Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEmailDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddEmailDialog(
        onSubmit: _handleAddEmail,
      ),
    );
  }

  Future<void> _handleAddEmail(String email, String totpSecret) async {
    try {
      await Provider.of<EmailPoolProvider>(context, listen: false)
          .addEmailToPool(email, totpSecret);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $email added to pool successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _copyTotpSecret(String secret) {
    Clipboard.setData(ClipboardData(text: secret));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 TOTP secret copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleEmailAction(String action, EmailPool email) {
    switch (action) {
      case 'view_totp':
        _showTotpDialog(email);
        break;
      case 'edit':
        _showEditEmailDialog(email);
        break;
      case 'delete':
        _showDeleteConfirmDialog(email);
        break;
    }
  }

  void _showTotpDialog(EmailPool email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TOTP Secret'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${email.email}'),
            const SizedBox(height: AppTheme.spacingM),
            const Text('TOTP Secret:'),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: SelectableText(
                email.totpSecret,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Keep this secret secure!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          CustomButton(
            text: 'Copy',
            onPressed: () {
              _copyTotpSecret(email.totpSecret);
              Navigator.of(context).pop();
            },
            fullWidth: false,
            width: 80,
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(EmailPool email) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditEmailDialog(
        email: email,
        onSubmit: (newEmail, newTotpSecret) => _handleUpdateEmail(email, newEmail, newTotpSecret),
      ),
    );
  }

  Future<void> _handleUpdateEmail(EmailPool email, String newEmail, String newTotpSecret) async {
    try {
      final updatedEmail = email.copyWith(
        email: newEmail,
        totpSecret: newTotpSecret,
        updatedAt: DateTime.now(),
      );
      
      await Provider.of<EmailPoolProvider>(context, listen: false)
          .updateEmailInPool(updatedEmail);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $newEmail updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(EmailPool email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this email from the pool?'),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: ${email.email}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Status: ${email.isAvailable ? 'Available' : 'Assigned'}',
                    style: TextStyle(
                      color: email.isAvailable ? AppTheme.successColor : AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!email.isAvailable) ...[
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: AppTheme.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        'This email is currently assigned to students!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            style: CustomButtonStyle.danger,
            onPressed: () => _handleDeleteEmail(email),
            fullWidth: false,
            width: 80,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteEmail(EmailPool email) async {
    try {
      Navigator.of(context).pop(); // Close dialog first
      
      await Provider.of<EmailPoolProvider>(context, listen: false)
          .deleteEmailFromPool(email.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${email.email} deleted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete email: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// SEPARATE DIALOG WIDGETS TO AVOID NAVIGATION CONFLICTS

class _AddEmailDialog extends StatefulWidget {
  final Function(String email, String totpSecret) onSubmit;

  const _AddEmailDialog({
    required this.onSubmit,
  });

  @override
  State<_AddEmailDialog> createState() => _AddEmailDialogState();
}

class _AddEmailDialogState extends State<_AddEmailDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Email to Pool'),
      content: SizedBox(
        width: 400,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                name: 'email',
                label: 'ChatGPT Email Address',
                hintText: 'Enter ChatGPT email address',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              CustomTextField(
                name: 'totpSecret',
                label: 'TOTP Secret',
                hintText: 'Enter TOTP secret key',
                prefixIcon: Icons.security,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(10),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        'TOTP secret is used for 2FA authentication. Keep it secure!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: _isSubmitting ? 'Adding...' : 'Add Email',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          fullWidth: false,
          width: 100,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final email = formData['email'] as String;
      final totpSecret = formData['totpSecret'] as String;
      
      setState(() => _isSubmitting = true);
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Then call the parent's submit handler
      await widget.onSubmit(email, totpSecret);
    }
  }
}

class _EditEmailDialog extends StatefulWidget {
  final EmailPool email;
  final Function(String email, String totpSecret) onSubmit;

  const _EditEmailDialog({
    required this.email,
    required this.onSubmit,
  });

  @override
  State<_EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<_EditEmailDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Email'),
      content: SizedBox(
        width: 400,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                name: 'email',
                label: 'ChatGPT Email Address',
                initialValue: widget.email.email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              CustomTextField(
                name: 'totpSecret',
                label: 'TOTP Secret',
                initialValue: widget.email.totpSecret,
                prefixIcon: Icons.security,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(10),
                ]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: _isSubmitting ? 'Updating...' : 'Update',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          fullWidth: false,
          width: 80,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final email = formData['email'] as String;
      final totpSecret = formData['totpSecret'] as String;
      
      setState(() => _isSubmitting = true);
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Then call the parent's submit handler
      await widget.onSubmit(email, totpSecret);
    }
  }
}