import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user's role (manager or worker)
  Future<String?> getUserRole() async {
    if (_auth.currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      print("Error getting user role: $e");
    }
    return null;
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Create a new user (admin only - creates account in Firestore, user signs up later)
  Future<void> createUserAccount({
    required String email,
    required String role, // 'manager' or 'worker'
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception("User with this email already exists");
      }

      // Create user document in Firestore (not yet authenticated)
      await _firestore.collection('users').add({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': null, // Will be filled when user signs up
        'status': 'pending', // pending, active, inactive
      });
    } catch (e) {
      print("Error creating user account: $e");
      rethrow;
    }
  }

  // When user signs up, link their Firestore user document to Firebase Auth
  Future<void> linkUserToAuth(String email, String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set({
        'email': email,
        'uid': uid,
        'status': 'active',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error linking user to auth: $e");
      rethrow;
    }
  }

  // Check if email is pre-authorized (admin created account)
  Future<bool> isEmailAuthorized(String email) async {
    try {
      final doc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return doc.docs.isNotEmpty;
    } catch (e) {
      print("Error checking email authorization: $e");
      return false;
    }
  }

  // Check if this is the first user (for initial setup)
  Future<bool> isFirstUser() async {
    try {
      final users = await _firestore.collection('users').limit(1).get();
      return users.docs.isEmpty;
    } catch (e) {
      print("Error checking first user: $e");
      return false;
    }
  }

  // Create admin user (only during initial setup)
  Future<void> createAdminUser(String email, String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'manager',
        'uid': uid,
        'status': 'active',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating admin user: $e");
      rethrow;
    }
  }

  // Update last login
  Future<void> updateLastLogin() async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating last login: $e");
    }
  }

  // Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}