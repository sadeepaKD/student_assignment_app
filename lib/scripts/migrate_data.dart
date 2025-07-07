// Corrected migration script - handles duplicate emails properly
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateExistingData() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    print('Starting data migration...');
    
    // Step 1: Create a map to track unique emails we've already processed
    Map<String, String> emailToDocId = {}; // email -> emailPool document ID
    
    // Step 2: Get all existing students
    final studentsSnapshot = await firestore.collection('students').get();
    
    print('Found ${studentsSnapshot.docs.length} students to process');
    
    // Step 3: First pass - collect all unique emails
    Set<String> uniqueEmails = {};
    Map<String, String> emailToTotpSecret = {};
    
    for (var studentDoc in studentsSnapshot.docs) {
      final studentData = studentDoc.data();
      final accounts = studentData['accounts'] as Map<String, dynamic>?;
      
      if (accounts != null) {
        for (var entry in accounts.entries) {
          final email = entry.key;
          final accountData = entry.value as Map<String, dynamic>;
          final totpSecret = accountData['secret'] ?? '';
          
          uniqueEmails.add(email);
          emailToTotpSecret[email] = totpSecret;
        }
      }
    }
    
    print('Found ${uniqueEmails.length} unique emails across all students');
    
    // Step 4: Create email pool entries (one per unique email)
    for (String email in uniqueEmails) {
      final totpSecret = emailToTotpSecret[email]!;
      
      print('Creating email pool entry for: $email');
      
      final emailDoc = await firestore.collection('emailPool').add({
        'email': email,
        'totpSecret': totpSecret,
        'isAvailable': false, // Will be assigned to students
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      emailToDocId[email] = emailDoc.id;
      print('  Created with ID: ${emailDoc.id}');
    }
    
    // Step 5: Second pass - create students and assignments
    for (var studentDoc in studentsSnapshot.docs) {
      final studentData = studentDoc.data();
      final whatsappNumber = studentDoc.id;
      final studentName = studentData['name'] ?? 'Unknown';
      
      print('Processing student: $studentName ($whatsappNumber)');
      
      // Create clean student record
      await firestore.collection('students').doc(whatsappNumber).set({
        'name': studentName,
        'whatsappNumber': whatsappNumber,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Process this student's email assignments
      final accounts = studentData['accounts'] as Map<String, dynamic>?;
      if (accounts != null) {
        for (var entry in accounts.entries) {
          final email = entry.key;
          final accountData = entry.value as Map<String, dynamic>;
          final emailDocId = emailToDocId[email]!; // Get the email pool ID
          
          print('  Creating assignment for email: $email');
          
          final dateAssigned = accountData['dateAssigned'] != null 
              ? (accountData['dateAssigned'] as Timestamp).toDate()
              : DateTime.now();
          final expiryDate = dateAssigned.add(const Duration(days: 30));
          
          await firestore.collection('assignments').add({
            'studentId': whatsappNumber,
            'emailId': emailDocId,
            'dateAssigned': Timestamp.fromDate(dateAssigned),
            'isActive': accountData['active'] ?? false,
            'expiryDate': Timestamp.fromDate(expiryDate),
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('    ✓ Assignment created');
        }
      }
    }
    
    print('\n🎉 Migration completed successfully!');
    print('📊 Summary:');
    print('  - Unique emails created in pool: ${uniqueEmails.length}');
    print('  - Students processed: ${studentsSnapshot.docs.length}');
    print('\n⚠️  Next steps:');
    print('  1. Test the new structure in your app');
    print('  2. Once confirmed working, you can remove the old "accounts" field from student documents');
    
  } catch (e) {
    print('❌ Migration failed: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}

// Helper function to clean up old structure after migration is confirmed working
Future<void> cleanupOldStructure() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🧹 Cleaning up old structure...');
  
  final studentsSnapshot = await firestore.collection('students').get();
  
  for (var studentDoc in studentsSnapshot.docs) {
    await studentDoc.reference.update({
      'accounts': FieldValue.delete(), // Remove the old accounts array
    });
    print('Cleaned up student: ${studentDoc.id}');
  }
  
  print('✅ Cleanup completed!');
}