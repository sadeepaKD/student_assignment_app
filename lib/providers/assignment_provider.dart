import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class AssignmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Assignment> _assignments = [];
  List<AssignmentWithDetails> _assignmentsWithDetails = [];
  Map<String, Student> _studentsCache = {};
  Map<String, EmailPool> _emailsCache = {};
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  List<Assignment> get assignments => _assignments;
  List<AssignmentWithDetails> get assignmentsWithDetails => _assignmentsWithDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  int get totalAssignments => _assignments.length;
  int get activeAssignments => _assignments.where((a) => a.isActive && !a.isExpired).length;
  int get expiredAssignments => _assignments.where((a) => a.isExpired).length;
  int get expiringAssignments => _assignments.where((a) => a.isActive && !a.isExpired && a.daysRemaining <= 7).length;

  bool get _isDataFresh {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes < 5;
  }

  Future<void> fetchAssignments({bool forceRefresh = false}) async {
    if (_isDataFresh && !forceRefresh && _assignmentsWithDetails.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _fetchAssignmentsData(),
        _fetchStudentsData(),
        _fetchEmailsData(),
      ]);

      await _buildAssignmentsWithDetails();

      _lastFetchTime = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _fetchAssignmentsData() async {
    final assignmentSnapshot = await _firestore
        .collection('assignments')
        .orderBy('dateAssigned', descending: true)
        .get();

    _assignments = assignmentSnapshot.docs.map((doc) {
      return Assignment.fromFirestore(doc);
    }).toList();
  }

  Future<void> _fetchStudentsData() async {
    final studentsSnapshot = await _firestore
        .collection('students')
        .get();

    _studentsCache.clear();
    for (var doc in studentsSnapshot.docs) {
      final student = Student.fromFirestore(doc);
      _studentsCache[student.id] = student;
    }
  }

  Future<void> _fetchEmailsData() async {
    final emailsSnapshot = await _firestore
        .collection('emailPool')
        .get();

    _emailsCache.clear();
    for (var doc in emailsSnapshot.docs) {
      final email = EmailPool.fromFirestore(doc);
      _emailsCache[email.id] = email;
    }
  }

  Future<void> _buildAssignmentsWithDetails() async {
    List<AssignmentWithDetails> detailedAssignments = [];

    for (Assignment assignment in _assignments) {
      final student = _studentsCache[assignment.studentId];
      final email = _emailsCache[assignment.emailId];

      if (student != null && email != null) {
        detailedAssignments.add(AssignmentWithDetails(
          assignment: assignment,
          student: student,
          email: email,
        ));
      }
    }

    _assignmentsWithDetails = detailedAssignments;
  }

  // FIXED: Create assignment - emails stay available for multiple students
  Future<void> createAssignment(String studentId, String emailId, {DateTime? customDate}) async {
    try {
      _setLoading(true);

      // Check if email exists (but don't check availability - emails can be shared)
      final email = _emailsCache[emailId];
      if (email == null) {
        throw Exception('Email not found');
      }

      // Check if this EXACT combination already exists and is active
      final existingAssignment = _assignments.any((a) => 
        a.studentId == studentId && 
        a.emailId == emailId && 
        a.isActive
      );

      if (existingAssignment) {
        throw Exception('This student already has this email assigned and active');
      }

      final assignmentDate = customDate ?? DateTime.now();
      final expiryDate = assignmentDate.add(const Duration(days: 30));

      final assignmentData = {
        'studentId': studentId,
        'emailId': emailId,
        'dateAssigned': Timestamp.fromDate(assignmentDate),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // FIXED: Only create assignment - don't update email availability
      final assignmentRef = _firestore.collection('assignments').doc();
      await assignmentRef.set(assignmentData);

      // Update local cache
      final newAssignment = Assignment(
        id: assignmentRef.id,
        studentId: studentId,
        emailId: emailId,
        dateAssigned: assignmentDate,
        expiryDate: expiryDate,
        isActive: true,
        createdAt: DateTime.now(),
      );

      _assignments.insert(0, newAssignment);
      
      // Note: Email stays available for other assignments
      await _buildAssignmentsWithDetails();
      
    } catch (e) {
      _setError('Failed to create assignment: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Toggle assignment - don't affect email availability
  Future<void> toggleAssignmentStatus(String assignmentId) async {
    try {
      final assignmentIndex = _assignments.indexWhere((a) => a.id == assignmentId);
      if (assignmentIndex == -1) {
        throw Exception('Assignment not found');
      }

      final assignment = _assignments[assignmentIndex];
      final newStatus = !assignment.isActive;

      // FIXED: Only update assignment status - don't touch email availability
      await _firestore.collection('assignments').doc(assignmentId).update({
        'isActive': newStatus,
      });

      // Update local cache
      _assignments[assignmentIndex] = Assignment(
        id: assignment.id,
        studentId: assignment.studentId,
        emailId: assignment.emailId,
        dateAssigned: assignment.dateAssigned,
        expiryDate: assignment.expiryDate,
        isActive: newStatus,
        createdAt: assignment.createdAt,
      );

      await _buildAssignmentsWithDetails();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // FIXED: Delete assignment - don't affect email availability
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      // FIXED: Only delete assignment - don't touch email availability
      await _firestore.collection('assignments').doc(assignmentId).delete();

      // Update local cache
      _assignments.removeWhere((a) => a.id == assignmentId);
      _assignmentsWithDetails.removeWhere((a) => a.assignment.id == assignmentId);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Extend assignment
  Future<void> extendAssignment(String assignmentId, int additionalDays) async {
    try {
      final assignmentIndex = _assignments.indexWhere((a) => a.id == assignmentId);
      if (assignmentIndex == -1) {
        throw Exception('Assignment not found');
      }

      final assignment = _assignments[assignmentIndex];
      final newExpiryDate = assignment.expiryDate.add(Duration(days: additionalDays));

      await _firestore.collection('assignments').doc(assignmentId).update({
        'expiryDate': Timestamp.fromDate(newExpiryDate),
      });

      _assignments[assignmentIndex] = Assignment(
        id: assignment.id,
        studentId: assignment.studentId,
        emailId: assignment.emailId,
        dateAssigned: assignment.dateAssigned,
        expiryDate: newExpiryDate,
        isActive: assignment.isActive,
        createdAt: assignment.createdAt,
      );

      await _buildAssignmentsWithDetails();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Get assignments for a specific student
  List<AssignmentWithDetails> getAssignmentsForStudent(String studentId) {
    return _assignmentsWithDetails
        .where((a) => a.assignment.studentId == studentId)
        .toList();
  }

  // Get assignments for a specific email
  List<AssignmentWithDetails> getAssignmentsForEmail(String emailId) {
    return _assignmentsWithDetails
        .where((a) => a.assignment.emailId == emailId)
        .toList();
  }

  // FIXED: Process expired assignments - only deactivate, don't touch email availability
  Future<void> processExpiredAssignments() async {
    try {
      final expiredAssignments = _assignments
          .where((a) => a.isActive && a.isExpired)
          .toList();

      if (expiredAssignments.isEmpty) return;

      // Use batch for multiple updates
      final batch = _firestore.batch();
      
      for (Assignment assignment in expiredAssignments) {
        batch.update(_firestore.collection('assignments').doc(assignment.id), {
          'isActive': false,
        });
      }

      await batch.commit();

      // Update local cache
      for (Assignment assignment in expiredAssignments) {
        final index = _assignments.indexWhere((a) => a.id == assignment.id);
        if (index != -1) {
          _assignments[index] = assignment.copyWith(isActive: false);
        }
      }

      await _buildAssignmentsWithDetails();
      notifyListeners();
    } catch (e) {
      _setError('Failed to process expired assignments: ${e.toString()}');
    }
  }

  // Filter assignments
  List<AssignmentWithDetails> filterAssignments({
    bool? isActive,
    bool? isExpired,
    bool? isExpiring,
  }) {
    return _assignmentsWithDetails.where((assignmentDetail) {
      final assignment = assignmentDetail.assignment;
      
      if (isActive != null && assignment.isActive != isActive) return false;
      if (isExpired != null && assignment.isExpired != isExpired) return false;
      if (isExpiring != null) {
        final isAssignmentExpiring = assignment.isActive && 
                                   !assignment.isExpired && 
                                   assignment.daysRemaining <= 7;
        if (isAssignmentExpiring != isExpiring) return false;
      }
      
      return true;
    }).toList();
  }

  void clearCache() {
    _studentsCache.clear();
    _emailsCache.clear();
    _lastFetchTime = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchAssignments(forceRefresh: true);
  }
}

class AssignmentWithDetails {
  final Assignment assignment;
  final Student student;
  final EmailPool email;

  AssignmentWithDetails({
    required this.assignment,
    required this.student,
    required this.email,
  });
}