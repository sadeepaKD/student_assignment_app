import 'dart:convert';
     import 'package:flutter/material.dart';
     import 'package:http/http.dart' as http;
     import 'package:cloud_firestore/cloud_firestore.dart';

     class TelegramBotProvider with ChangeNotifier {
       final FirebaseFirestore _db = FirebaseFirestore.instance;
       List<Map<String, dynamic>> _pendingRequests = [];
       List<Map<String, dynamic>> _attempts = [];
       bool _isLoading = false;
       String? _error;
       String _searchQuery = '';

       List<Map<String, dynamic>> get pendingRequests => _pendingRequests.where((req) =>
           req['telegramId'].toString().contains(_searchQuery) ||
           req['whatsappNumber'].toString().contains(_searchQuery)).toList();
       List<Map<String, dynamic>> get attempts => _attempts.where((att) =>
           att['telegramId'].toString().contains(_searchQuery)).toList();
       bool get isLoading => _isLoading;
       String? get error => _error;

       void setSearchQuery(String query) {
         _searchQuery = query.toLowerCase();
         notifyListeners();
       }

       Future<void> fetchAllData() async {
         _isLoading = true;
         _error = null;
         notifyListeners();

         try {
           final pendingSnapshot = await _db.collection('pending_links').get();
           _pendingRequests = pendingSnapshot.docs.map((doc) => doc.data()).toList();

           final attemptsSnapshot = await _db.collection('otp_attempts').get();
           _attempts = attemptsSnapshot.docs.map((doc) => doc.data()).toList();
         } catch (e) {
           _error = e.toString();
         }

         _isLoading = false;
         notifyListeners();
       }

       Future<void> approveRequest(String telegramId, String whatsappNumber) async {
         _isLoading = true;
         notifyListeners();

         try {
           await _db.collection('links').add({'telegramId': telegramId, 'whatsappNumber': whatsappNumber});
           final snapshot = await _db.collection('pending_links')
               .where('telegramId', isEqualTo: telegramId)
               .where('whatsappNumber', isEqualTo: whatsappNumber)
               .get();
           for (var doc in snapshot.docs) {
             await _db.collection('pending_links').doc(doc.id).delete();
           }
           final botToken = '7874539745:AAFN4ND227SwXtl3TAmB-fyAMdo9toPmXw0'; // Secure this (e.g., Firebase Remote Config)
           final url = 'https://api.telegram.org/bot$botToken/sendMessage';
           await http.post(
             Uri.parse(url),
             body: jsonEncode({
               'chat_id': telegramId,
               'text': '✅ You’ve been approved! Please send your ChatGPT OTP screenshot to get your OTPs.',
             }),
             headers: {'Content-Type': 'application/json'},
           );
           await fetchAllData();
         } catch (e) {
           _error = e.toString();
         }

         _isLoading = false;
         notifyListeners();
       }
     }