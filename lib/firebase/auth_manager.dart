import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInForUserRegistration(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> registerUserAndSendVerification(final String email, final String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _auth.currentUser!.sendEmailVerification();
    return true;
  }

  Future<bool> hasUserVerifiedEmail() async {
    await _auth.currentUser!.reload();
    return _auth.currentUser!.emailVerified;
  }

  Future<String> loginAndReturnAuthID(String email, String password) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user!.uid;
  }

  String whoAmI() {
    String message = 'The current auth user is ${_auth.currentUser}';
    debugPrint(message);
    return message;
  }
}
