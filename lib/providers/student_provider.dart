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

  // CORRECTED: Add student with WhatsApp number as document ID (no isActive)
  Future<void> addStudent(String name, String whatsappNumber) async {
    try {
      // Clean the WhatsApp number (remove spaces, special chars)
      final cleanWhatsAppNumber = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Check if student with this WhatsApp number already exists
      final existingDoc = await _firestore
          .collection('students')
          .doc(cleanWhatsAppNumber) // Use WhatsApp number as document ID
          .get();

      if (existingDoc.exists) {
        throw Exception('A student with this WhatsApp number already exists');
      }

      final now = DateTime.now();
      final studentData = {
        'name': name,
        'whatsappNumber': cleanWhatsAppNumber,
        // REMOVED: No isActive field needed in students collection
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Use WhatsApp number as document ID
      await _firestore
          .collection('students')
          .doc(cleanWhatsAppNumber)
          .set(studentData);

      // Create a new student object and add to local list
      final newStudent = Student(
        id: cleanWhatsAppNumber, // WhatsApp number as ID
        name: name,
        whatsappNumber: cleanWhatsAppNumber,
        isActive: true, // Default true for compatibility (but not stored in DB)
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
      // Clean the WhatsApp number
      final cleanWhatsAppNumber = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // If WhatsApp number changed, we need to handle document ID change
      if (cleanWhatsAppNumber != studentId) {
        // Check if new WhatsApp number already exists
        final existingDoc = await _firestore
            .collection('students')
            .doc(cleanWhatsAppNumber)
            .get();

        if (existingDoc.exists) {
          throw Exception('A student with this WhatsApp number already exists');
        }

        // Get current student data
        final currentDoc = await _firestore
            .collection('students')
            .doc(studentId)
            .get();

        if (!currentDoc.exists) {
          throw Exception('Student not found');
        }

        // Create new document with new WhatsApp number as ID
        await _firestore
            .collection('students')
            .doc(cleanWhatsAppNumber)
            .set({
          'name': name,
          'whatsappNumber': cleanWhatsAppNumber,
          // REMOVED: No isActive field
          'createdAt': currentDoc.data()!['createdAt'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update any assignments that reference the old student ID
        final assignmentQuery = await _firestore
            .collection('assignments')
            .where('studentId', isEqualTo: studentId)
            .get();

        final batch = _firestore.batch();
        for (var assignmentDoc in assignmentQuery.docs) {
          batch.update(assignmentDoc.reference, {
            'studentId': cleanWhatsAppNumber,
          });
        }
        await batch.commit();

        // Delete old document
        await _firestore.collection('students').doc(studentId).delete();

        // Update local list
        final index = _students.indexWhere((s) => s.id == studentId);
        if (index != -1) {
          _students[index] = _students[index].copyWith(
            id: cleanWhatsAppNumber,
            name: name,
            whatsappNumber: cleanWhatsAppNumber,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      } else {
        // Simple update - WhatsApp number didn't change
        await _firestore.collection('students').doc(studentId).update({
          'name': name,
          'whatsappNumber': cleanWhatsAppNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local list
        final index = _students.indexWhere((s) => s.id == studentId);
        if (index != -1) {
          _students[index] = _students[index].copyWith(
            name: name,
            whatsappNumber: cleanWhatsAppNumber,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // REMOVED: toggleStudentStatus method (not needed)

  // Delete a student (with proper assignment handling)
  Future<void> deleteStudent(String studentId) async {
    try {
      // Check if student has any assignments (active or inactive)
      final assignments = await _firestore
          .collection('assignments')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (assignments.docs.isNotEmpty) {
        throw Exception(
          'Cannot delete student with existing assignments. '
          'Please remove all assignments first.\n\n'
          'Found ${assignments.docs.length} assignment(s).'
        );
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

  // Get student by WhatsApp number (document ID)
  Future<Student?> getStudentByWhatsApp(String whatsappNumber) async {
    try {
      final cleanWhatsAppNumber = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
      final doc = await _firestore
          .collection('students')
          .doc(cleanWhatsAppNumber)
          .get();

      if (doc.exists) {
        return Student.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get student by ID (same as WhatsApp number)
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

  // Get student's active assignments count
  Future<int> getActiveAssignmentsCount(String studentId) async {
    try {
      final assignments = await _firestore
          .collection('assignments')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return assignments.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get all assignments for a student (FIXED: Better error handling and logging)
  Future<List<Map<String, dynamic>>> getStudentAssignments(String studentId) async {
    try {
      print('🔍 Searching for assignments for student: $studentId'); // Debug log
      
      final assignments = await _firestore
          .collection('assignments')
          .where('studentId', isEqualTo: studentId)
          .get();
      
      print('📋 Found ${assignments.docs.length} assignments'); // Debug log
      
      if (assignments.docs.isEmpty) {
        // Also try searching without orderBy in case there's an index issue
        final allAssignments = await _firestore
            .collection('assignments')
            .get();
        
        print('📊 Total assignments in database: ${allAssignments.docs.length}'); // Debug log
        
        // Filter manually to debug
        final matchingAssignments = allAssignments.docs.where((doc) {
          final data = doc.data();
          final docStudentId = data['studentId'];
          print('🔍 Checking assignment ${doc.id}: studentId = $docStudentId'); // Debug log
          return docStudentId == studentId;
        }).toList();
        
        print('✅ Manually filtered assignments: ${matchingAssignments.length}'); // Debug log
        
        return matchingAssignments.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }
      
      return assignments.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching assignments: $e'); // Debug log
      return [];
    }
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

  // MIGRATION HELPER: Convert existing random ID documents to WhatsApp ID structure
  Future<void> migrateToWhatsAppIds() async {
    try {
      _setLoading(true);
      
      final allStudents = await _firestore.collection('students').get();
      final batch = _firestore.batch();
      
      for (var doc in allStudents.docs) {
        final data = doc.data();
        final whatsappNumber = data['whatsappNumber'] as String;
        final cleanWhatsAppNumber = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
        
        // If document ID is not the WhatsApp number, migrate it
        if (doc.id != cleanWhatsAppNumber) {
          // Create new document with WhatsApp number as ID
          final newDocRef = _firestore.collection('students').doc(cleanWhatsAppNumber);
          
          // Clean the data - remove isActive if it exists
          final cleanData = Map<String, dynamic>.from(data);
          cleanData.remove('isActive'); // Remove if exists
          cleanData['whatsappNumber'] = cleanWhatsAppNumber;
          
          batch.set(newDocRef, cleanData);
          
          // Update assignments to reference new student ID
          final assignments = await _firestore
              .collection('assignments')
              .where('studentId', isEqualTo: doc.id)
              .get();
          
          for (var assignment in assignments.docs) {
            batch.update(assignment.reference, {'studentId': cleanWhatsAppNumber});
          }
          
          // Delete old document
          batch.delete(doc.reference);
        } else {
          // Document ID is correct, but remove isActive field if it exists
          if (data.containsKey('isActive')) {
            batch.update(doc.reference, {
              'isActive': FieldValue.delete(),
            });
          }
        }
      }
      
      await batch.commit();
      await fetchStudents(); // Refresh the list
      
    } catch (e) {
      _setError('Migration failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}