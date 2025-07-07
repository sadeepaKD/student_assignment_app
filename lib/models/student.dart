import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Check if assignment is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  // Days remaining before expiry
  int get daysRemaining {
    final difference = expiryDate.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }
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