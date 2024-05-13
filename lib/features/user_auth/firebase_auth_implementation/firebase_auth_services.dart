import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../global/common/toast.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Sign in user
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user is an admin
      bool isAdmin = await isUserAdmin(email);

      // If user is admin, display error message and sign them out
      if (isAdmin) {
        showToast(
            message:
                'Admin accounts are not allowed to sign in via mobile app.');
        await _auth.signOut();
        return null;
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    }
    return null;
  }

  Future<bool> isUserAdmin(String email) async {
    try {
      // Query the Firestore collection where admin users are stored
      QuerySnapshot querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

      // If any documents match the query, the user is an admin
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking admin status: $e');
      return false; // Return false in case of any error
    }
  }
}
