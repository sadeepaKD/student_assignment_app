import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/email_pool_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/student.dart';

class AssignmentManagementScreen extends StatefulWidget {
  const AssignmentManagementScreen({super.key});

  @override
  State<AssignmentManagementScreen> createState() => _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final emailProvider = Provider.of<EmailPoolProvider>(context, listen: false);

    final futures = <Future>[];
    
    futures.add(assignmentProvider.fetchAssignments());
    
    if (studentProvider.students.isEmpty) {
      futures.add(studentProvider.fetchStudents());
    }
    
    if (emailProvider.emailPool.isEmpty) {
      futures.add(emailProvider.loadEmailPool());
    }

    try {
      await Future.wait(futures);
      await assignmentProvider.processExpiredAssignments();
      _isInitialized = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Management'),
        actions: [
          Consumer<AssignmentProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : _processExpiredAssignments,
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Process Expired Assignments',
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomButton(
              text: 'New Assignment',
              icon: Icons.assignment_add,
              onPressed: _showCreateAssignmentDialog,
              fullWidth: false,
              width: 160,
            ),
          ),
        ],
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, assignmentProvider, child) {
          if (assignmentProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Loading assignments...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (assignmentProvider.error != null) {
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
                      'Error: ${assignmentProvider.error}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () {
                      assignmentProvider.clearError();
                      _initializeData();
                    },
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
                _buildSearchAndFilters(),
                const SizedBox(height: AppTheme.spacingL),
                _buildStatsCards(assignmentProvider),
                const SizedBox(height: AppTheme.spacingXl),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Assignments',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Monitor and manage student email assignments',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildFilterDropdown(),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          Expanded(
                            child: _buildAssignmentsList(assignmentProvider),
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

  Widget _buildSearchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by student name, email, or WhatsApp...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All Assignments')),
          DropdownMenuItem(value: 'active', child: Text('Active Only')),
          DropdownMenuItem(value: 'expired', child: Text('Expired Only')),
          DropdownMenuItem(value: 'expiring', child: Text('Expiring Soon')),
          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedFilter = value!;
          });
        },
      ),
    );
  }

  Widget _buildStatsCards(AssignmentProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Assignments',
                  provider.totalAssignments.toString(),
                  Icons.assignment,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  provider.activeAssignments.toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Expiring Soon',
                  provider.expiringAssignments.toString(),
                  Icons.warning,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Expired',
                  provider.expiredAssignments.toString(),
                  Icons.cancel,
                  AppTheme.errorColor,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      provider.totalAssignments.toString(),
                      Icons.assignment,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      provider.activeAssignments.toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Expiring',
                      provider.expiringAssignments.toString(),
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      'Expired',
                      provider.expiredAssignments.toString(),
                      Icons.cancel,
                      AppTheme.errorColor,
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

  Widget _buildAssignmentsList(AssignmentProvider provider) {
    List<AssignmentWithDetails> filteredAssignments = _getFilteredAssignments(provider);

    if (filteredAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'all' ? Icons.assignment_outlined : Icons.filter_list_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _selectedFilter == 'all' 
                  ? 'No assignments found' 
                  : 'No assignments match the current filter',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _selectedFilter == 'all' 
                  ? 'Create assignments to link students with email accounts' 
                  : 'Try selecting a different filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            CustomButton(
              text: _selectedFilter == 'all' ? 'Create First Assignment' : 'Show All',
              icon: _selectedFilter == 'all' ? Icons.assignment_add : Icons.clear_all,
              onPressed: _selectedFilter == 'all' 
                  ? _showCreateAssignmentDialog 
                  : () {
                      setState(() {
                        _selectedFilter = 'all';
                      });
                    },
              fullWidth: false,
              width: 180,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredAssignments.length,
      itemBuilder: (context, index) {
        final assignmentDetail = filteredAssignments[index];
        return _ImprovedAssignmentCard(
          key: ValueKey(assignmentDetail.assignment.id),
          assignmentDetail: assignmentDetail,
          onActionSelected: _handleAssignmentAction,
        );
      },
    );
  }

  List<AssignmentWithDetails> _getFilteredAssignments(AssignmentProvider provider) {
    List<AssignmentWithDetails> assignments;

    switch (_selectedFilter) {
      case 'active':
        assignments = provider.filterAssignments(isActive: true, isExpired: false);
        break;
      case 'expired':
        assignments = provider.filterAssignments(isExpired: true);
        break;
      case 'expiring':
        assignments = provider.filterAssignments(isExpiring: true);
        break;
      case 'inactive':
        assignments = provider.filterAssignments(isActive: false);
        break;
      default:
        assignments = provider.assignmentsWithDetails;
    }

    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      assignments = assignments.where((assignmentDetail) {
        return assignmentDetail.student.name.toLowerCase().contains(query) ||
               assignmentDetail.student.whatsappNumber.contains(query) ||
               assignmentDetail.email.email.toLowerCase().contains(query);
      }).toList();
    }

    return assignments;
  }

  // IMPROVED CREATE ASSIGNMENT DIALOG WITH BETTER UI
  void _showCreateAssignmentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minWidth: MediaQuery.of(context).size.width * 0.9 > 600 
                ? 600 
                : MediaQuery.of(context).size.width * 0.9,
          ),
          child: const ImprovedCreateAssignmentDialog(),
        ),
      ),
    );
  }

  // Other methods remain the same...
  void _handleAssignmentAction(String action, AssignmentWithDetails assignmentDetail) {
    switch (action) {
      case 'toggle':
        _toggleAssignmentStatus(assignmentDetail);
        break;
      case 'extend':
        _showExtendAssignmentDialog(assignmentDetail);
        break;
      case 'delete':
        _showDeleteConfirmDialog(assignmentDetail);
        break;
    }
  }

  void _toggleAssignmentStatus(AssignmentWithDetails assignmentDetail) async {
    try {
      await Provider.of<AssignmentProvider>(context, listen: false)
          .toggleAssignmentStatus(assignmentDetail.assignment.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Assignment ${assignmentDetail.assignment.isActive ? 'deactivated' : 'activated'}!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showExtendAssignmentDialog(AssignmentWithDetails assignmentDetail) {
    final formKey = GlobalKey<FormBuilderState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Assignment'),
        content: SizedBox(
          width: 400,
          child: FormBuilder(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Extend assignment for ${assignmentDetail.student.name}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppTheme.spacingL),
                FormBuilderDropdown<int>(
                  name: 'additionalDays',
                  decoration: const InputDecoration(
                    labelText: 'Extend by',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  validator: FormBuilderValidators.required(),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 14, child: Text('14 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 60, child: Text('60 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current expiry: ${DateFormat('MMM dd, yyyy').format(assignmentDetail.assignment.expiryDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Days remaining: ${assignmentDetail.assignment.daysRemaining}',
                        style: Theme.of(context).textTheme.bodySmall,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Extend',
            onPressed: () => _handleExtendAssignment(formKey, assignmentDetail),
            fullWidth: false,
            width: 100,
          ),
        ],
      ),
    );
  }

  void _handleExtendAssignment(
      GlobalKey<FormBuilderState> formKey, 
      AssignmentWithDetails assignmentDetail) async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;
      final additionalDays = formData['additionalDays'] as int;
      
      Navigator.of(context).pop();
      
      try {
        await Provider.of<AssignmentProvider>(context, listen: false)
            .extendAssignment(assignmentDetail.assignment.id!, additionalDays);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Assignment extended by $additionalDays days!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to extend assignment: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showDeleteConfirmDialog(AssignmentWithDetails assignmentDetail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this assignment?'),
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
                    'Student: ${assignmentDetail.student.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('Email: ${assignmentDetail.email.email}'),
                  Text(
                    'Assigned: ${DateFormat('MMM dd, yyyy').format(assignmentDetail.assignment.dateAssigned)}',
                  ),
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
              child: const Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppTheme.errorColor,
                    size: 16,
                  ),
                  SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'This will free up the email for reassignment',
                      style: TextStyle(
                        color: AppTheme.errorColor,
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
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            style: CustomButtonStyle.danger,
            onPressed: () => _handleDeleteAssignment(assignmentDetail),
            fullWidth: false,
            width: 80,
          ),
        ],
      ),
    );
  }

  void _handleDeleteAssignment(AssignmentWithDetails assignmentDetail) async {
    Navigator.of(context).pop();
    
    try {
      await Provider.of<AssignmentProvider>(context, listen: false)
          .deleteAssignment(assignmentDetail.assignment.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Assignment deleted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _processExpiredAssignments() async {
    try {
      await Provider.of<AssignmentProvider>(context, listen: false)
          .processExpiredAssignments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expired assignments processed!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to process expired assignments: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// IMPROVED CREATE ASSIGNMENT DIALOG
class ImprovedCreateAssignmentDialog extends StatefulWidget {
  const ImprovedCreateAssignmentDialog({Key? key}) : super(key: key);

  @override
  State<ImprovedCreateAssignmentDialog> createState() => _ImprovedCreateAssignmentDialogState();
}

class _ImprovedCreateAssignmentDialogState extends State<ImprovedCreateAssignmentDialog> {
  final TextEditingController _studentSearchController = TextEditingController();
  final TextEditingController _emailSearchController = TextEditingController();
  Student? _selectedStudent;
  EmailPool? _selectedEmail;
  DateTime? _selectedDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _studentSearchController.dispose();
    _emailSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusL),
              topRight: Radius.circular(AppTheme.radiusL),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_add, color: Colors.white, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              const Expanded(
                child: Text(
                  'Create New Assignment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Selection
                _buildSectionTitle('Select Student'),
                const SizedBox(height: AppTheme.spacingS),
                _buildStudentSelector(),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Email Selection
                _buildSectionTitle('Select Email'),
                const SizedBox(height: AppTheme.spacingS),
                _buildEmailSelector(),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Optional Date
                _buildSectionTitle('Assignment Date (Optional)'),
                const SizedBox(height: AppTheme.spacingS),
                _buildDateSelector(),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Info Box
                _buildInfoBox(),
              ],
            ),
          ),
        ),

        // Footer Actions
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.radiusL),
              bottomRight: Radius.circular(AppTheme.radiusL),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppTheme.spacingM),
              CustomButton(
                text: _isCreating ? 'Creating...' : 'Create Assignment',
                onPressed: _isCreating || _selectedStudent == null || _selectedEmail == null 
                    ? null 
                    : _handleCreateAssignment,
                fullWidth: false,
                width: 160,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        final availableStudents = studentProvider.students
            .where((s) => s.isActive)
            .toList();

        if (availableStudents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_off,
            title: 'No Active Students',
            subtitle: 'Please add active students first',
          );
        }

        return Column(
          children: [
            // Search Field
            TextField(
              controller: _studentSearchController,
              decoration: InputDecoration(
                hintText: 'Search students by name or WhatsApp...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _studentSearchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _studentSearchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Selected Student Display
            if (_selectedStudent != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.successColor),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStudent!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          Text(
                            _selectedStudent!.whatsappNumber,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedStudent = null),
                      icon: const Icon(Icons.close, color: AppTheme.successColor),
                    ),
                  ],
                ),
              )
            else
              // Student List
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: _buildStudentList(availableStudents),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStudentList(List<Student> students) {
    final query = _studentSearchController.text.toLowerCase();
    final filteredStudents = query.isEmpty
        ? students
        : students.where((s) => 
            s.name.toLowerCase().contains(query) ||
            s.whatsappNumber.contains(query)
          ).toList();

    if (filteredStudents.isEmpty) {
      return const Center(
        child: Text('No students match your search'),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            student.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(student.whatsappNumber),
          onTap: () => setState(() => _selectedStudent = student),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
        );
      },
    );
  }

  Widget _buildEmailSelector() {
    return Consumer<EmailPoolProvider>(
      builder: (context, emailProvider, child) {
        final availableEmails = emailProvider.emailPool.toList(); // FIXED: All emails available

        if (availableEmails.isEmpty) {
          return _buildEmptyState(
            icon: Icons.email_outlined,
            title: 'No Emails Found',
            subtitle: 'Please add emails to the pool first',
          );
        }

        return Column(
          children: [
            // Search Field
            TextField(
              controller: _emailSearchController,
              decoration: InputDecoration(
                hintText: 'Search emails...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _emailSearchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _emailSearchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Selected Email Display
            if (_selectedEmail != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.successColor),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        _selectedEmail!.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedEmail = null),
                      icon: const Icon(Icons.close, color: AppTheme.successColor),
                    ),
                  ],
                ),
              )
            else
              // Email List
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: _buildEmailList(availableEmails),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmailList(List<EmailPool> emails) {
    final query = _emailSearchController.text.toLowerCase();
    final filteredEmails = query.isEmpty
        ? emails
        : emails.where((e) => e.email.toLowerCase().contains(query)).toList();

    if (filteredEmails.isEmpty) {
      return const Center(
        child: Text('No emails match your search'),
      );
    }

    return ListView.builder(
      itemCount: filteredEmails.length,
      itemBuilder: (context, index) {
        final email = filteredEmails[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.email, color: Colors.white),
          ),
          title: Text(
            email.email,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () => setState(() => _selectedEmail = email),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                    : 'Use current date (${DateFormat('MMM dd, yyyy').format(DateTime.now())})',
                style: TextStyle(
                  color: _selectedDate != null ? null : AppTheme.textSecondary,
                ),
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                onPressed: () => setState(() => _selectedDate = null),
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assignment Details',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  '• Assignment will expire 30 days from the assignment date\n'
                  '• Email will be marked as unavailable for other assignments\n'
                  '• You can extend or deactivate assignments later',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _handleCreateAssignment() async {
    if (_selectedStudent == null || _selectedEmail == null) return;

    setState(() => _isCreating = true);

    try {
      await Provider.of<AssignmentProvider>(context, listen: false)
          .createAssignment(
            _selectedStudent!.id!,
            _selectedEmail!.id!,
            customDate: _selectedDate,
          );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Assignment created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

// IMPROVED ASSIGNMENT CARD WITH BETTER LAYOUT
class _ImprovedAssignmentCard extends StatelessWidget {
  final AssignmentWithDetails assignmentDetail;
  final Function(String, AssignmentWithDetails) onActionSelected;

  const _ImprovedAssignmentCard({
    Key? key,
    required this.assignmentDetail,
    required this.onActionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assignment = assignmentDetail.assignment;
    final student = assignmentDetail.student;
    final email = assignmentDetail.email;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (assignment.isExpired) {
      statusColor = AppTheme.errorColor;
      statusText = 'EXPIRED';
      statusIcon = Icons.cancel;
    } else if (!assignment.isActive) {
      statusColor = AppTheme.textTertiary;
      statusText = 'INACTIVE';
      statusIcon = Icons.pause_circle;
    } else if (assignment.daysRemaining <= 7) {
      statusColor = AppTheme.warningColor;
      statusText = 'EXPIRING SOON';
      statusIcon = Icons.warning;
    } else {
      statusColor = AppTheme.successColor;
      statusText = 'ACTIVE';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with better spacing
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: AppTheme.spacingXs),
                          Text(
                            student.whatsappNumber,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                PopupMenuButton<String>(
                  onSelected: (value) => onActionSelected(value, assignmentDetail),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(assignment.isActive ? Icons.pause : Icons.play_arrow, size: 18),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(assignment.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'extend',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18),
                          SizedBox(width: AppTheme.spacingS),
                          Text('Extend'),
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
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Email and Date Info in a better layout
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  // Email Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: const Icon(
                          Icons.email, 
                          size: 16, 
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Email',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              email.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingM),
                  
                  // Date Information Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Date',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(assignment.dateAssigned),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(assignment.expiryDate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: assignment.isExpired ? AppTheme.errorColor : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: assignment.isExpired 
                              ? AppTheme.errorColor.withOpacity(0.1)
                              : assignment.daysRemaining <= 7
                                  ? AppTheme.warningColor.withOpacity(0.1)
                                  : AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Column(
                          children: [
                            Text(
                              assignment.isExpired 
                                  ? 'EXPIRED'
                                  : '${assignment.daysRemaining}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: assignment.isExpired 
                                    ? AppTheme.errorColor
                                    : assignment.daysRemaining <= 7
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor,
                              ),
                            ),
                            if (!assignment.isExpired)
                              Text(
                                'days left',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: assignment.daysRemaining <= 7
                                      ? AppTheme.warningColor
                                      : AppTheme.successColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}