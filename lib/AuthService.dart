import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _profileId;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _generateProfileId(user);
      } else {
        _profileId = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get profileId => _profileId;
  bool get isLoggedIn => _user != null;

  // Generate a profile ID from user's first name plus a hash
  Future<void> _generateProfileId(User user) async {
    // Extract first name from display name
    String? displayName = user.displayName;
    if (displayName == null || displayName.isEmpty) {
      displayName = "user";
    }

    String firstName = displayName.split(' ')[0].toLowerCase();

    // Generate a hash from the user ID for uniqueness
    var bytes = utf8.encode(user.uid);
    var digest = sha256.convert(bytes);
    String hash = digest.toString().substring(0, 5);

    // Combine first name and hash
    String generatedProfileId = '$firstName-$hash';

    // Check if this is the first login, if so create a user document
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'profileId': generatedProfileId,
        'createdAt': FieldValue.serverTimestamp(),
        'topFive': {
          'movies': [],
          'books': [],
          'musician_band': [],
          'travel_locations': [],
          'customCategories': [],
        }
      });
    } else {
      // Get existing profile ID
      generatedProfileId = (userDoc.data() as Map<String, dynamic>)['profileId'];
    }

    _profileId = generatedProfileId;
    notifyListeners();
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Check if a user is the owner of a particular profile page
  bool isProfileOwner(String profileId) {
    return _profileId == profileId;
  }
}