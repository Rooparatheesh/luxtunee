import 'package:flutter/material.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }
}
