import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class StudentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Legacy method names for compatibility
  Future<void> loadStudents() => fetchStudents();

  // Fetch all students from Firestore
  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('students')
          .orderBy('createdAt', descending: true)
          .get();

      _students = querySnapshot.docs.map((doc) {
        return Student.fromFirestore(doc);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Add a new student
  Future<void> addStudent(String name, String whatsappNumber) async {
    try {
      // Check if WhatsApp number already exists
      final existingStudent = await _firestore
          .collection('students')
          .where('whatsappNumber', isEqualTo: whatsappNumber)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        throw Exception('A student with this WhatsApp number already exists');
      }

      final now = DateTime.now();
      final studentData = {
        'name': name,
        'whatsappNumber': whatsappNumber,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('students').add(studentData);

      // Create a new student object and add to local list
      final newStudent = Student(
        id: docRef.id,
        name: name,
        whatsappNumber: whatsappNumber,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      _students.insert(0, newStudent);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update student information
  Future<void> updateStudent(String studentId, String name, String whatsappNumber) async {
    try {
      // Check if WhatsApp number already exists for another student
      final existingStudent = await _firestore
          .collection('students')
          .where('whatsappNumber', isEqualTo: whatsappNumber)
          .get();

      if (existingStudent.docs.isNotEmpty && existingStudent.docs.first.id != studentId) {
        throw Exception('A student with this WhatsApp number already exists');
      }

      await _firestore.collection('students').doc(studentId).update({
        'name': name,
        'whatsappNumber': whatsappNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index = _students.indexWhere((s) => s.id == studentId);
      if (index != -1) {
        _students[index] = _students[index].copyWith(
          name: name,
          whatsappNumber: whatsappNumber,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Toggle student active status
  Future<void> toggleStudentStatus(String studentId) async {
    try {
      final studentIndex = _students.indexWhere((s) => s.id == studentId);
      if (studentIndex == -1) {
        throw Exception('Student not found');
      }

      final currentStatus = _students[studentIndex].isActive;
      final newStatus = !currentStatus;

      await _firestore.collection('students').doc(studentId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      _students[studentIndex] = _students[studentIndex].copyWith(
        isActive: newStatus,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Delete a student
  Future<void> deleteStudent(String studentId) async {
    try {
      // Check if student has any active assignments
      final assignments = await _firestore
          .collection('assignments')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      if (assignments.docs.isNotEmpty) {
        throw Exception('Cannot delete student with active assignments. Please deactivate assignments first.');
      }

      // Delete the student
      await _firestore.collection('students').doc(studentId).delete();

      // Remove from local list
      _students.removeWhere((s) => s.id == studentId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Get student by WhatsApp number
  Future<Student?> getStudentByWhatsApp(String whatsappNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('whatsappNumber', isEqualTo: whatsappNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Student.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      
      if (doc.exists) {
        return Student.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Search students by name or WhatsApp number
  List<Student> searchStudents(String query) {
    if (query.isEmpty) return _students;
    
    final lowerQuery = query.toLowerCase();
    return _students.where((student) {
      return student.name.toLowerCase().contains(lowerQuery) ||
             student.whatsappNumber.contains(query);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await fetchStudents();
  }
}