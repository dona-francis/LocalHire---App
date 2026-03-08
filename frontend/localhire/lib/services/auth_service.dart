import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Hash password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 📲 Send OTP
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

  // 🔢 Verify OTP
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {

    PhoneAuthCredential credential =
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

    await _auth.signInWithCredential(credential);

    // 🔥 IMPORTANT: Sign out immediately (we don't use FirebaseAuth session)
    await _auth.signOut();
  }

  // 🔑 Login (Username + Password)
  Future<String?> loginUser({
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
      return userDoc.id;   // ✅ return Firestore document ID
    }

    return null;
  }
}