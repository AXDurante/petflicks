import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to track auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign Up
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name
      await credential.user?.updateDisplayName(name);

      // Write additional user info (username) to Firestore
      await _firestore.collection('Users').doc(credential.user!.uid).set({
        'username': username,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // Email & Password Sign In
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // Helper method to convert error codes to user-friendly messages
  String _getAuthExceptionMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'An unknown error occurred.';
    }
  }
}
