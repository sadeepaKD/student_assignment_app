import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/theme.dart';
import '../../providers/student_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/student.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomButton(
              text: 'Add Student',
              icon: Icons.person_add,
              onPressed: _showAddStudentDialog,
              fullWidth: false,
              width: 130,
            ),
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentProvider.error != null) {
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
                      'Error: ${studentProvider.error}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () => studentProvider.fetchStudents(),
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
                // Search Bar
                _buildSearchBar(),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Stats (simplified - no active/inactive distinction)
                _buildStatsCards(studentProvider),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Students List
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Students Directory',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            'Manage student records and their information',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          
                          Expanded(
                            child: _buildStudentsList(studentProvider.students),
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

  Widget _buildSearchBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search students by name or WhatsApp number...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
          ),
          onChanged: (value) {
            setState(() {
              // Trigger rebuild to filter students
            });
          },
        ),
      ),
    );
  }

  // SIMPLIFIED: Only show total students count
  Widget _buildStatsCards(StudentProvider provider) {
    final totalStudents = provider.students.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Total Students',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              totalStudents.toString(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(List<Student> allStudents) {
    // Filter students based on search
    final filteredStudents = _getFilteredStudents(allStudents);

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _searchController.text.isEmpty 
                  ? 'No students found' 
                  : 'No students match your search',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _searchController.text.isEmpty 
                  ? 'Add students to get started' 
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            CustomButton(
              text: _searchController.text.isEmpty ? 'Add First Student' : 'Clear Search',
              icon: _searchController.text.isEmpty ? Icons.person_add : Icons.clear,
              onPressed: _searchController.text.isEmpty 
                  ? _showAddStudentDialog 
                  : () {
                      _searchController.clear();
                      setState(() {});
                    },
              fullWidth: false,
              width: 160,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  List<Student> _getFilteredStudents(List<Student> students) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return students;
    
    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
             student.whatsappNumber.contains(query);
    }).toList();
  }

  // SIMPLIFIED: Removed isActive status display and toggle option
  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spacingXs),
                Text(student.whatsappNumber),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Show student ID (WhatsApp number)
            Row(
              children: [
                const Icon(Icons.badge, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  'ID: ${student.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleStudentAction(value, student),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: AppTheme.spacingS),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'assignments',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment, size: 18),
                  SizedBox(width: AppTheme.spacingS),
                  Text('View Assignments'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                  SizedBox(width: AppTheme.spacingS),
                  Text(
                    'Delete', 
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddStudentDialog(
        onSubmit: _handleAddStudent,
      ),
    );
  }

  Future<void> _handleAddStudent(String name, String whatsappNumber) async {
    try {
      await Provider.of<StudentProvider>(context, listen: false)
          .addStudent(name.trim(), whatsappNumber.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $name added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add student: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleStudentAction(String action, Student student) {
    switch (action) {
      case 'edit':
        _showEditStudentDialog(student);
        break;
      case 'assignments':
        _showStudentAssignments(student);
        break;
      case 'delete':
        _showDeleteConfirmDialog(student);
        break;
    }
  }

  void _showEditStudentDialog(Student student) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditStudentDialog(
        student: student,
        onSubmit: (name, whatsappNumber) => _handleUpdateStudent(student, name, whatsappNumber),
      ),
    );
  }

  Future<void> _handleUpdateStudent(Student student, String name, String whatsappNumber) async {
    try {
      await Provider.of<StudentProvider>(context, listen: false)
          .updateStudent(student.id, name.trim(), whatsappNumber.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${student.name} updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update student: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // NEW: Show student assignments with better debugging
  void _showStudentAssignments(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${student.name}\'s Assignments'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Provider.of<StudentProvider>(context, listen: false)
                .getStudentAssignments(student.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: AppTheme.spacingM),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }
              
              final assignments = snapshot.data ?? [];
              
              // DEBUG INFO
              print('🔍 Student ID: ${student.id}');
              print('📋 Assignments found: ${assignments.length}');
              for (var assignment in assignments) {
                print('📄 Assignment: ${assignment['id']} - Active: ${assignment['isActive']}');
              }
              
              if (assignments.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textTertiary),
                    const SizedBox(height: AppTheme.spacingM),
                    const Text('No assignments found'),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // DEBUG INFO DISPLAY
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Info:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text('Student ID: ${student.id}'),
                          Text('Student Name: ${student.name}'),
                          Text('WhatsApp: ${student.whatsappNumber}'),
                          const SizedBox(height: AppTheme.spacingS),
                          const Text(
                            'Check browser console for more details',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              
              return ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final isActive = assignment['isActive'] ?? false;
                  
                  DateTime? dateAssigned;
                  DateTime? expiryDate;
                  
                  try {
                    if (assignment['dateAssigned'] != null) {
                      dateAssigned = (assignment['dateAssigned'] as Timestamp).toDate();
                    }
                    if (assignment['expiryDate'] != null) {
                      expiryDate = (assignment['expiryDate'] as Timestamp).toDate();
                    }
                  } catch (e) {
                    print('❌ Error parsing dates: $e');
                  }
                  
                  final emailId = assignment['emailId'] ?? 'Unknown';
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      title: Text('Email ID: $emailId'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dateAssigned != null)
                            Text('Assigned: ${dateAssigned.toString().substring(0, 10)}'),
                          if (expiryDate != null)
                            Text('Expires: ${expiryDate.toString().substring(0, 10)}'),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // DEBUG: Show assignment ID
                          Text(
                            'Assignment ID: ${assignment['id']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => _DeleteStudentDialog(
        student: student,
        onConfirm: () => _handleDeleteStudent(student),
      ),
    );
  }

  Future<void> _handleDeleteStudent(Student student) async {
    try {
      await Provider.of<StudentProvider>(context, listen: false)
          .deleteStudent(student.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${student.name} deleted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete student: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _DeleteStudentDialog extends StatefulWidget {
  final Student student;
  final VoidCallback onConfirm;

  const _DeleteStudentDialog({
    required this.student,
    required this.onConfirm,
  });

  @override
  State<_DeleteStudentDialog> createState() => _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends State<_DeleteStudentDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Student'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this student?'),
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
                  'Name: ${widget.student.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('WhatsApp: ${widget.student.whatsappNumber}'),
                Text('ID: ${widget.student.id}'),
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
                    'This action cannot be undone!',
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
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: _isDeleting ? 'Deleting...' : 'Delete',
          style: CustomButtonStyle.danger,
          isLoading: _isDeleting,
          onPressed: _isDeleting ? null : _handleDelete,
          fullWidth: false,
          width: 80,
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    
    // Close dialog first
    Navigator.of(context).pop();
    
    // Then call the parent's delete handler
    widget.onConfirm();
  }
}

// SEPARATE DIALOG WIDGETS TO AVOID NAVIGATION CONFLICTS

class _AddStudentDialog extends StatefulWidget {
  final Function(String name, String whatsappNumber) onSubmit;

  const _AddStudentDialog({
    required this.onSubmit,
  });

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Student'),
      content: SizedBox(
        width: 400,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                name: 'name',
                label: 'Full Name',
                hintText: 'Enter student\'s full name',
                prefixIcon: Icons.person,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              CustomTextField(
                name: 'whatsappNumber',
                label: 'WhatsApp Number',
                hintText: 'Enter WhatsApp number (e.g., 447123456789)',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(10),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              Container(
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
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        'WhatsApp number will be used as the student ID',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
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
          text: _isSubmitting ? 'Adding...' : 'Add Student',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          fullWidth: false,
          width: 120,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final name = formData['name'] as String;
      final whatsappNumber = formData['whatsappNumber'] as String;
      
      setState(() => _isSubmitting = true);
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Then call the parent's submit handler
      await widget.onSubmit(name, whatsappNumber);
    }
  }
}

class _EditStudentDialog extends StatefulWidget {
  final Student student;
  final Function(String name, String whatsappNumber) onSubmit;

  const _EditStudentDialog({
    required this.student,
    required this.onSubmit,
  });

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Student'),
      content: SizedBox(
        width: 400,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                name: 'name',
                label: 'Full Name',
                initialValue: widget.student.name,
                prefixIcon: Icons.person,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              CustomTextField(
                name: 'whatsappNumber',
                label: 'WhatsApp Number',
                initialValue: widget.student.whatsappNumber,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(10),
                ]),
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        'Changing WhatsApp number will update the student ID and all related assignments',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
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
          text: _isSubmitting ? 'Updating...' : 'Update',
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
      final name = formData['name'] as String;
      final whatsappNumber = formData['whatsappNumber'] as String;
      
      setState(() => _isSubmitting = true);
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Then call the parent's submit handler
      await widget.onSubmit(name, whatsappNumber);
    }
  }
}