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
  bool _showStats = false;

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
        title: const Text('Assignments'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onPressed: () => setState(() => _showStats = !_showStats),
            tooltip: _showStats ? 'Hide Stats' : 'Show Stats',
            iconSize: 18,
          ),
          Consumer<AssignmentProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : _processExpiredAssignments,
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Process Expired',
                iconSize: 18,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: CustomButton(
              text: 'New',
              icon: Icons.add,
              onPressed: _showCreateAssignmentDialog,
              fullWidth: false,
              width: 70,
              height: 32,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth > 600 ? AppTheme.spacingS : AppTheme.spacingXs;
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchAndFilters(),
                if (_showStats) _buildStatsSummary(),
                const SizedBox(height: AppTheme.spacingXs),
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assignments',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          _buildFilterDropdown(),
                          const SizedBox(height: AppTheme.spacingXs),
                          Expanded(
                            child: _buildAssignmentsList(),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXs),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6.0),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Total', provider.totalAssignments.toString(), AppTheme.primaryColor),
                  _buildStatItem('Active', provider.activeAssignments.toString(), AppTheme.successColor),
                  _buildStatItem('Expiring', provider.expiringAssignments.toString(), AppTheme.warningColor),
                  _buildStatItem('Expired', provider.expiredAssignments.toString(), AppTheme.errorColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All')),
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'expired', child: Text('Expired')),
          DropdownMenuItem(value: 'expiring', child: Text('Expiring')),
          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedFilter = value!;
          });
        },
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textPrimary,
          fontSize: 12,
        ),
        dropdownColor: AppTheme.cardColor,
        iconSize: 16,
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, child) {
        List<AssignmentWithDetails> filteredAssignments = _getFilteredAssignments(provider);

        if (filteredAssignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedFilter == 'all' ? Icons.assignment_outlined : Icons.filter_list_off,
                  size: 40,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  _selectedFilter == 'all' 
                      ? 'No assignments found' 
                      : 'No matches for filter',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                CustomButton(
                  text: _selectedFilter == 'all' ? 'Create Assignment' : 'Show All',
                  icon: _selectedFilter == 'all' ? Icons.add : Icons.clear_all,
                  onPressed: _selectedFilter == 'all' 
                      ? _showCreateAssignmentDialog 
                      : () {
                          setState(() {
                            _selectedFilter = 'all';
                          });
                        },
                  fullWidth: false,
                  width: 140,
                  height: 32,
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
                  'Extend for ${assignmentDetail.student.name}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppTheme.spacingS),
                FormBuilderDropdown<int>(
                  name: 'additionalDays',
                  decoration: const InputDecoration(
                    labelText: 'Days',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  validator: FormBuilderValidators.required(),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7')),
                    DropdownMenuItem(value: 14, child: Text('14')),
                    DropdownMenuItem(value: 30, child: Text('30')),
                    DropdownMenuItem(value: 60, child: Text('60')),
                    DropdownMenuItem(value: 90, child: Text('90')),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expires: ${DateFormat('MMM dd, yyyy').format(assignmentDetail.assignment.expiryDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Days Left: ${assignmentDetail.assignment.daysRemaining}',
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
            width: 80,
            height: 32,
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
              content: Text('✅ Extended by $additionalDays days!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to extend: $e'),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm deletion?'),
            const SizedBox(height: AppTheme.spacingXs),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXs),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            style: CustomButtonStyle.danger,
            onPressed: () => _handleDeleteAssignment(dialogContext, assignmentDetail),
            fullWidth: false,
            width: 70,
            height: 32,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAssignment(BuildContext dialogContext, AssignmentWithDetails assignmentDetail) async {
    Navigator.of(dialogContext).pop();
    
    try {
      await Provider.of<AssignmentProvider>(context, listen: false)
          .deleteAssignment(assignmentDetail.assignment.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Deleted!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
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
            content: Text('✅ Processed!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

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
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusL),
              topRight: Radius.circular(AppTheme.radiusL),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.add, color: Colors.white, size: 24),
              const SizedBox(width: AppTheme.spacingS),
              const Expanded(
                child: Text(
                  'New Assignment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Student'),
                const SizedBox(height: AppTheme.spacingXs),
                _buildStudentSelector(),
                const SizedBox(height: AppTheme.spacingM),
                _buildSectionTitle('Email'),
                const SizedBox(height: AppTheme.spacingXs),
                _buildEmailSelector(),
                const SizedBox(height: AppTheme.spacingM),
                _buildSectionTitle('Date (Optional)'),
                const SizedBox(height: AppTheme.spacingXs),
                _buildDateSelector(),
                const SizedBox(height: AppTheme.spacingS),
                _buildInfoBox(),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
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
              const SizedBox(width: AppTheme.spacingS),
              CustomButton(
                text: _isCreating ? 'Creating...' : 'Create',
                onPressed: _isCreating || _selectedStudent == null || _selectedEmail == null 
                    ? null 
                    : _handleCreateAssignment,
                fullWidth: false,
                width: 100,
                height: 32,
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
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
            title: 'No Students',
            subtitle: 'Add active students first',
          );
        }

        return Column(
          children: [
            TextField(
              controller: _studentSearchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _studentSearchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _studentSearchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            if (_selectedStudent != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppTheme.successColor, size: 16),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        _selectedStudent!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedStudent = null),
                      icon: const Icon(Icons.close, color: AppTheme.successColor, size: 16),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
        child: Text('No matches', style: TextStyle(fontSize: 12)),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          title: Text(
            student.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => setState(() => _selectedStudent = student),
          contentPadding: const EdgeInsets.all(AppTheme.spacingXs),
        );
      },
    );
  }

  Widget _buildEmailSelector() {
    return Consumer<EmailPoolProvider>(
      builder: (context, emailProvider, child) {
        final availableEmails = emailProvider.emailPool.toList();

        if (availableEmails.isEmpty) {
          return _buildEmptyState(
            icon: Icons.email_outlined,
            title: 'No Emails',
            subtitle: 'Add emails first',
          );
        }

        return Column(
          children: [
            TextField(
              controller: _emailSearchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _emailSearchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _emailSearchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            if (_selectedEmail != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppTheme.successColor, size: 16),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        _selectedEmail!.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedEmail = null),
                      icon: const Icon(Icons.close, color: AppTheme.successColor, size: 16),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
        child: Text('No matches', style: TextStyle(fontSize: 12)),
      );
    }

    return ListView.builder(
      itemCount: filteredEmails.length,
      itemBuilder: (context, index) {
        final email = filteredEmails[index];
        return ListTile(
          leading: const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.email, color: Colors.white, size: 12),
          ),
          title: Text(
            email.email,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => setState(() => _selectedEmail = email),
          contentPadding: const EdgeInsets.all(AppTheme.spacingXs),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingXs),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                    : 'Use current date (${DateFormat('MMM dd, yyyy').format(DateTime.now())})',
                style: TextStyle(
                  color: _selectedDate != null ? null : AppTheme.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                onPressed: () => setState(() => _selectedDate = null),
                icon: const Icon(Icons.clear, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXs),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              'Expires in 30 days, email unavailable, extendable later',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppTheme.textTertiary),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
              fontSize: 10,
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
            content: Text('✅ Created!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
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
      statusText = 'EXPIRING';
      statusIcon = Icons.warning;
    } else {
      statusColor = AppTheme.successColor;
      statusText = 'ACTIVE';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                        ),
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
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
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              email.email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM dd').format(assignment.dateAssigned),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const Text(' - '),
                          Text(
                            DateFormat('MMM dd').format(assignment.expiryDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: assignment.isExpired ? AppTheme.errorColor : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(assignment.isActive ? Icons.pause : Icons.play_arrow),
                      onPressed: () => onActionSelected('toggle', assignmentDetail),
                      tooltip: assignment.isActive ? 'Deactivate' : 'Activate',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () => onActionSelected('extend', assignmentDetail),
                      tooltip: 'Extend',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => onActionSelected('delete', assignmentDetail),
                      tooltip: 'Delete',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  assignment.isExpired ? 'Expired' : '${assignment.daysRemaining}d',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: assignment.isExpired 
                        ? AppTheme.errorColor
                        : assignment.daysRemaining <= 7
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}