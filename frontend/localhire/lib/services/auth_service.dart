import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //  Hash password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  //  Send OTP
  Future<void> sendOTP({
    required String phone,
    required Function(String verificationId) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        print("OTP Failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onCodeSent(verificationId);
      },
    );
  }

  //  Verify OTP — keeps Firebase Auth session alive 
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    //  Keep session alive — no signOut
    await _auth.signInWithCredential(credential);
  }

  //  Step 1 of Login — check username/password, return phone number
  // Returns phone if valid, null if invalid
  Future<String?> checkCredentials({
    required String username,
    required String password,
  }) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (query.docs.isEmpty) return null;

    final userDoc = query.docs.first;
    final storedHash = userDoc['password'];
    final enteredHash = hashPassword(password);

    if (storedHash == enteredHash) {
      //  Return phone number so login screen can trigger OTP
      return userDoc['phone'] as String;
    }

    return null;
  }

  //  Step 2 of Login — after OTP verified, get userId
  Future<String?> getUserIdByPhone(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  //  Save session
  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  //  Get session
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Logout — clears everything
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await _auth.signOut();
  }
}