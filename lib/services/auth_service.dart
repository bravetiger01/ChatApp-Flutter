import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign up new user
  Future<User?> signUp(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred.user;
  }

  // Sign in existing user
  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // // Sign in with Google (also registers new users automatically)
  // Future<UserCredential?> signInWithGoogle() async {
  //   try {
  //     // Trigger the authentication flow
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       throw Exception('Google Sign-In was cancelled by the user');
  //     }

  //     // Obtain the auth details from the request
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;

  //     // Create a new credential
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Sign in with the credential (registers new user if not existing)
  //     UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );

  //     // Store user data in Firestore if it's a new user
  //     if (userCredential.additionalUserInfo?.isNewUser ?? false) {
  //       await _db.collection('users').doc(userCredential.user!.uid).set({
  //         'uid': userCredential.user!.uid,
  //         'email': userCredential.user!.email,
  //         'name': userCredential.user!.displayName,
  //         'photoURL': userCredential.user!.photoURL,
  //         'createdAt': FieldValue.serverTimestamp(),
  //       });
  //     }

  //     return userCredential;
  //   } on FirebaseAuthException {
  //     rethrow; // Caller handles specific Firebase errors
  //   } catch (e) {
  //     throw Exception(
  //       'Error signing in with Google: $e',
  //     ); // Throw for caller to handle
  //   }
  // }
  // Sign out

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Current logged in user
  User? get currentUser => _auth.currentUser;
}
