import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Added this import for Color and IconData

class Student {
  final String id;
  final String name;
  final String whatsappNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.name,
    required this.whatsappNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    
    return Student(
      id: doc.id,
      name: data['name'] ?? '',
      whatsappNumber: data['whatsappNumber'] ?? doc.id,
      isActive: data['isActive'] ?? true,
      // Handle null Timestamps safely
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : now,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'whatsappNumber': whatsappNumber,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? whatsappNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmailPool {
  final String id;
  final String email;
  final String totpSecret;
  final bool isAvailable;
  final String? assignedToStudentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailPool({
    required this.id,
    required this.email,
    required this.totpSecret,
    this.isAvailable = true,
    this.assignedToStudentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmailPool.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    
    return EmailPool(
      id: doc.id,
      email: data['email'] ?? '',
      totpSecret: data['totpSecret'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      assignedToStudentId: data['assignedToStudentId'],
      // Handle null Timestamps safely
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : now,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'totpSecret': totpSecret,
      'isAvailable': isAvailable,
      'assignedToStudentId': assignedToStudentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EmailPool copyWith({
    String? id,
    String? email,
    String? totpSecret,
    bool? isAvailable,
    String? assignedToStudentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailPool(
      id: id ?? this.id,
      email: email ?? this.email,
      totpSecret: totpSecret ?? this.totpSecret,
      isAvailable: isAvailable ?? this.isAvailable,
      assignedToStudentId: assignedToStudentId ?? this.assignedToStudentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Assignment {
  final String id;
  final String studentId; // WhatsApp number
  final String emailId; // Email pool document ID
  final DateTime dateAssigned;
  final bool isActive;
  final DateTime expiryDate;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.studentId,
    required this.emailId,
    required this.dateAssigned,
    this.isActive = true,
    required this.expiryDate,
    required this.createdAt,
  });

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    
    return Assignment(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      emailId: data['emailId'] ?? '',
      dateAssigned: data['dateAssigned'] != null 
          ? (data['dateAssigned'] as Timestamp).toDate() 
          : now,
      isActive: data['isActive'] ?? true,
      expiryDate: data['expiryDate'] != null 
          ? (data['expiryDate'] as Timestamp).toDate() 
          : now.add(const Duration(days: 30)),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'emailId': emailId,
      'dateAssigned': Timestamp.fromDate(dateAssigned),
      'isActive': isActive,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // REMOVED: Duplicate methods that are now in the extension
  // The extension provides these same methods with additional functionality
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin', 'user'
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : now,
      lastLoginAt: data['lastLoginAt'] != null 
          ? (data['lastLoginAt'] as Timestamp).toDate() 
          : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  bool get isAdmin => role == 'admin';
}

// ENHANCED Assignment Extension with all functionality
extension AssignmentExtensions on Assignment {
  // Check if assignment is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  // Check if assignment is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (isExpired || !isActive) return false;
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  // Days remaining before expiry (can be negative if expired)
  int get daysRemaining {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  // Human readable status
  String get statusText {
    if (isExpired) return 'EXPIRED';
    if (!isActive) return 'INACTIVE';
    if (isExpiringSoon) return 'EXPIRING SOON';
    return 'ACTIVE';
  }

  // Status color for UI
  Color get statusColor {
    if (isExpired) return const Color(0xFFEF4444); // Red
    if (!isActive) return const Color(0xFF94A3B8); // Gray
    if (isExpiringSoon) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFF10B981); // Green
  }

  // Status icon for UI
  IconData get statusIcon {
    if (isExpired) return Icons.cancel;
    if (!isActive) return Icons.pause_circle;
    if (isExpiringSoon) return Icons.warning;
    return Icons.check_circle;
  }

  // Copy method for Assignment
  Assignment copyWith({
    String? id,
    String? studentId,
    String? emailId,
    DateTime? dateAssigned,
    bool? isActive,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      emailId: emailId ?? this.emailId,
      dateAssigned: dateAssigned ?? this.dateAssigned,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}