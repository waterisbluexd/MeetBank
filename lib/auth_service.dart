import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        print('Google Sign-In authentication not supported on this platform');
        return null;
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        print('Google Sign-In canceled by user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      if (googleAuth.idToken == null) {
        print('Failed to get Google ID token');
        return null;
      }
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);

    } on PlatformException catch (e) {
      print('Google Sign-In PlatformException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}