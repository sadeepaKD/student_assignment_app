import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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
                
                // Stats
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

  Widget _buildStatsCards(StudentProvider provider) {
    final totalStudents = provider.students.length;
    final activeStudents = provider.students.where((s) => s.isActive).length;
    final inactiveStudents = totalStudents - activeStudents;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Students',
                  totalStudents.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Active Students',
                  activeStudents.toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Inactive Students',
                  inactiveStudents.toString(),
                  Icons.cancel,
                  AppTheme.warningColor,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatCard(
                'Total Students',
                totalStudents.toString(),
                Icons.people,
                AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      activeStudents.toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildStatCard(
                      'Inactive',
                      inactiveStudents.toString(),
                      Icons.cancel,
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

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: CircleAvatar(
          backgroundColor: student.isActive 
              ? AppTheme.primaryColor 
              : AppTheme.textTertiary,
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
            Row(
              children: [
                Icon(
                  student.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: student.isActive ? AppTheme.successColor : AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  student.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: student.isActive ? AppTheme.successColor : AppTheme.warningColor,
                    fontWeight: FontWeight.w500,
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
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    student.isActive ? Icons.block : Icons.check_circle,
                    size: 18,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(student.isActive ? 'Deactivate' : 'Activate'),
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
    final formKey = GlobalKey<FormBuilderState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SizedBox(
          width: 400,
          child: FormBuilder(
            key: formKey,
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
            text: 'Add Student',
            onPressed: () => _handleAddStudent(formKey),
            fullWidth: false,
            width: 120,
          ),
        ],
      ),
    );
  }

  void _handleAddStudent(GlobalKey<FormBuilderState> formKey) async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;
      final name = formData['name'] as String;
      final whatsappNumber = formData['whatsappNumber'] as String;
      
      Navigator.of(context).pop(); // Close dialog
      
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
  }

  void _handleStudentAction(String action, Student student) {
    switch (action) {
      case 'edit':
        _showEditStudentDialog(student);
        break;
      case 'toggle':
        _toggleStudentStatus(student);
        break;
      case 'delete':
        _showDeleteConfirmDialog(student);
        break;
    }
  }

  void _showEditStudentDialog(Student student) {
    final formKey = GlobalKey<FormBuilderState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SizedBox(
          width: 400,
          child: FormBuilder(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  name: 'name',
                  label: 'Full Name',
                  initialValue: student.name,
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
                  initialValue: student.whatsappNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Update',
            onPressed: () => _handleUpdateStudent(formKey, student),
            fullWidth: false,
            width: 100,
          ),
        ],
      ),
    );
  }

  void _handleUpdateStudent(GlobalKey<FormBuilderState> formKey, Student student) async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;
      final name = formData['name'] as String;
      final whatsappNumber = formData['whatsappNumber'] as String;
      
      Navigator.of(context).pop(); // Close dialog
      
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
  }

  void _toggleStudentStatus(Student student) async {
    try {
      await Provider.of<StudentProvider>(context, listen: false)
          .toggleStudentStatus(student.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${student.name} ${student.isActive ? 'deactivated' : 'activated'} successfully!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update student status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    'Name: ${student.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('WhatsApp: ${student.whatsappNumber}'),
                  Text(
                    'Status: ${student.isActive ? 'Active' : 'Inactive'}',
                    style: TextStyle(
                      color: student.isActive ? AppTheme.successColor : AppTheme.warningColor,
                    ),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            style: CustomButtonStyle.danger,
            onPressed: () => _handleDeleteStudent(student),
            fullWidth: false,
            width: 80,
          ),
        ],
      ),
    );
  }

  void _handleDeleteStudent(Student student) async {
    Navigator.of(context).pop(); // Close dialog
    
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