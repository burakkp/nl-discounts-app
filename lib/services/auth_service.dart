import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';

class AuthService {
  // Use a getter so we don't instantly invoke FirebaseAuth.instance on object creation
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Logs the user in anonymously and returns the fresh JWT Token
  Future<String> getValidToken() async {
    // Use Firebase REST API on Linux Desktop since native Firebase Auth isn't fully supported
    if (!kIsWeb && Platform.isLinux) {
      print('⚠️ Using Firebase REST API for anonymous Auth on Linux Desktop...');
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully fetched real JWT token via REST API');
        return data['idToken'] as String;
      } else {
        throw Exception('REST API Auth failed: ${response.statusCode} - ${response.body}');
      }
    }

    User? user = _auth.currentUser;

    // If not logged in, log in anonymously
    if (user == null) {
      print('🔐 No user found. Logging in anonymously...');
      UserCredential credential = await _auth.signInAnonymously();
      user = credential.user;
    }

    // Force refresh the token to ensure it hasn't expired
    if (user != null) {
      print('🔑 Fetching fresh JWT token from Firebase...');
      return await user.getIdToken(true) ?? '';
    }

    throw Exception("Failed to authenticate user.");
  }
}