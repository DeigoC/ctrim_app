import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  Future signInForUserRegistration(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future signOut() async {
    await _auth.signOut();
  }

  Future<String> registerUserAndGetUID(String email, String password) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return cred.user!.uid;
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
