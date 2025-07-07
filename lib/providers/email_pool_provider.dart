import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class EmailPoolProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<EmailPool> _emailPool = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EmailPool> get emailPool => _emailPool;
  List<EmailPool> get availableEmails => _emailPool.where((e) => e.isAvailable).toList();
  List<EmailPool> get assignedEmails => _emailPool.where((e) => !e.isAvailable).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Statistics
  int get totalEmails => _emailPool.length;
  int get availableEmailsCount => availableEmails.length;
  int get assignedEmailsCount => assignedEmails.length;

  Future<void> loadEmailPool() async {
    try {
      _setLoading(true);
      _clearError();
      
      final querySnapshot = await _firestore
          .collection('emailPool')
          .orderBy('createdAt', descending: true)
          .get();
      
      _emailPool = querySnapshot.docs
          .map((doc) => EmailPool.fromFirestore(doc))
          .toList();
          
    } catch (e) {
      _setError('Failed to load email pool: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEmailToPool(String email, String totpSecret) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check if email already exists
      final existingEmail = _emailPool.any((e) => e.email == email);
      if (existingEmail) {
        throw Exception('Email already exists in the pool');
      }
      
      final emailPool = EmailPool(
        id: '', // Will be set by Firestore
        email: email,
        totpSecret: totpSecret,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final docRef = await _firestore.collection('emailPool').add(emailPool.toFirestore());
      
      final newEmailPool = emailPool.copyWith(id: docRef.id);
      _emailPool.insert(0, newEmailPool);
      
    } catch (e) {
      _setError('Failed to add email to pool: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEmailInPool(EmailPool emailPool) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestore
          .collection('emailPool')
          .doc(emailPool.id)
          .update(emailPool.toFirestore());
      
      final index = _emailPool.indexWhere((e) => e.id == emailPool.id);
      if (index != -1) {
        _emailPool[index] = emailPool;
      }
      
    } catch (e) {
      _setError('Failed to update email in pool: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEmailFromPool(String emailId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestore.collection('emailPool').doc(emailId).delete();
      
      _emailPool.removeWhere((email) => email.id == emailId);
      
    } catch (e) {
      _setError('Failed to delete email from pool: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignEmailToStudent(String emailId, String studentId) async {
    try {
      final emailIndex = _emailPool.indexWhere((e) => e.id == emailId);
      if (emailIndex == -1) return;
      
      final email = _emailPool[emailIndex];
      if (!email.isAvailable) {
        throw Exception('Email is already assigned');
      }
      
      final updatedEmail = email.copyWith(
        isAvailable: false,
        assignedToStudentId: studentId,
        updatedAt: DateTime.now(),
      );
      
      await updateEmailInPool(updatedEmail);
      
    } catch (e) {
      _setError('Failed to assign email to student: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> unassignEmailFromStudent(String emailId) async {
    try {
      final emailIndex = _emailPool.indexWhere((e) => e.id == emailId);
      if (emailIndex == -1) return;
      
      final email = _emailPool[emailIndex];
      final updatedEmail = email.copyWith(
        isAvailable: true,
        assignedToStudentId: null,
        updatedAt: DateTime.now(),
      );
      
      await updateEmailInPool(updatedEmail);
      
    } catch (e) {
      _setError('Failed to unassign email from student: ${e.toString()}');
      rethrow;
    }
  }

  EmailPool? getEmailById(String emailId) {
    try {
      return _emailPool.firstWhere((e) => e.id == emailId);
    } catch (e) {
      return null;
    }
  }

  List<EmailPool> getEmailsForStudent(String studentId) {
    return _emailPool
        .where((e) => e.assignedToStudentId == studentId)
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}