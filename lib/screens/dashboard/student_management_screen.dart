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
        title: const Text('Students'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        toolbarHeight: 48,
        actions: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: CustomButton(
              text: 'Add',
              icon: Icons.person_add,
              onPressed: _showAddStudentDialog,
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
                _buildSearchBar(),
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
                            'Students',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Expanded(
                            child: _buildStudentsList(),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXs),
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
    );
  }

  Widget _buildStudentsList() {
    return Consumer<StudentProvider>(
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
                  size: 40,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
                  child: Text(
                    'Error: ${studentProvider.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                CustomButton(
                  text: 'Retry',
                  onPressed: () => studentProvider.fetchStudents(),
                  fullWidth: false,
                  width: 80,
                  height: 32,
                ),
              ],
            ),
          );
        }

        final filteredStudents = _getFilteredStudents(studentProvider.students);

        if (filteredStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchController.text.isEmpty ? Icons.people_outline : Icons.search_off,
                  size: 40,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  _searchController.text.isEmpty 
                      ? 'No students found' 
                      : 'No matches',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                CustomButton(
                  text: _searchController.text.isEmpty ? 'Add Student' : 'Clear',
                  icon: _searchController.text.isEmpty ? Icons.person_add : Icons.clear,
                  onPressed: _searchController.text.isEmpty 
                      ? _showAddStudentDialog 
                      : () {
                          _searchController.clear();
                          setState(() {});
                        },
                  fullWidth: false,
                  width: 120,
                  height: 32,
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

  Widget _buildStudentCard(Student student) {
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
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
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleStudentAction(value, student),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: AppTheme.spacingXs),
                                Text('Edit', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'assignments',
                            child: Row(
                              children: [
                                Icon(Icons.assignment, size: 16),
                                SizedBox(width: AppTheme.spacingXs),
                                Text('Assignments', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                                SizedBox(width: AppTheme.spacingXs),
                                Text('Delete', style: TextStyle(fontSize: 12, color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                        ],
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
                    children: [
                      Icon(Icons.badge, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        'ID: ${student.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            content: Text('✅ $name added!'),
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
            content: Text('✅ ${student.name} updated!'),
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

  void _showStudentAssignments(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${student.name}\'s Assignments'),
        content: SizedBox(
          width: 500,
          height: 300,
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
                      const Icon(Icons.error, size: 32, color: AppTheme.errorColor),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text('Error: ${snapshot.error}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              }
              
              final assignments = snapshot.data ?? [];
              
              if (assignments.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 32, color: AppTheme.textTertiary),
                    const SizedBox(height: AppTheme.spacingXs),
                    const Text('No assignments'),
                    const SizedBox(height: AppTheme.spacingXs),
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
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                    child: ListTile(
                      leading: Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                        size: 20,
                      ),
                      title: Text('Email: $emailId', style: Theme.of(context).textTheme.bodySmall),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dateAssigned != null)
                            Text('Assigned: ${dateAssigned.toString().substring(0, 10)}', style: Theme.of(context).textTheme.bodySmall),
                          if (expiryDate != null)
                            Text('Expires: ${expiryDate.toString().substring(0, 10)}', style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive ? AppTheme.successColor : AppTheme.errorColor,
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
            content: Text('🗑️ ${student.name} deleted!'),
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
                  'Name: ${widget.student.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('WhatsApp: ${widget.student.whatsappNumber}'),
                Text('ID: ${widget.student.id}'),
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
          width: 70,
          height: 32,
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    Navigator.of(context).pop();
    widget.onConfirm();
  }
}

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
      title: const Text('Add Student'),
      content: SizedBox(
        width: 400,
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                name: 'name',
                label: 'Name',
                hintText: 'Enter name',
                prefixIcon: Icons.person,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              const SizedBox(height: AppTheme.spacingS),
              CustomTextField(
                name: 'whatsappNumber',
                label: 'WhatsApp',
                hintText: 'e.g., 447123456789',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(10),
                ]),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        'WhatsApp is the student ID',
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
          text: _isSubmitting ? 'Adding...' : 'Add',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _handleSubmit,
          fullWidth: false,
          width: 80,
          height: 32,
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
      Navigator.of(context).pop();
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
                label: 'Name',
                initialValue: widget.student.name,
                prefixIcon: Icons.person,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              const SizedBox(height: AppTheme.spacingS),
              CustomTextField(
                name: 'whatsappNumber',
                label: 'WhatsApp',
                initialValue: widget.student.whatsappNumber,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(10),
                ]),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 16),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        'Changing WhatsApp updates ID and assignments',
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
          width: 80,
          height: 32,
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
      Navigator.of(context).pop();
      await widget.onSubmit(name, whatsappNumber);
    }
  }
}