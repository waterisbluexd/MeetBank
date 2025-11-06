import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignInAccount? _cachedUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Use popup for web, native flow for mobile
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // Mobile platform (Android/iOS)
        final GoogleSignIn signIn = GoogleSignIn.instance;

        // Set up listener before authenticating
        final completer = Completer<GoogleSignInAccount?>();
        late StreamSubscription subscription;

        subscription = signIn.authenticationEvents.listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _cachedUser = event.user;
            if (!completer.isCompleted) {
              subscription.cancel();
              completer.complete(event.user);
            }
          }
        });

        try {
          // Trigger authentication
          await signIn.authenticate();

          // Wait for the user with timeout
          final googleUser = await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              subscription.cancel();
              return null;
            },
          );

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
        } finally {
          subscription.cancel();
        }
      }
    } on PlatformException catch (e) {
      print('Google Sign-In PlatformException: ${e.code} - ${e.message}');
      return null;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return null;
    } on GoogleSignInException catch (e) {
      print('GoogleSignInException: ${e.code} - ${e.description}');
      return null;
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn.instance.disconnect();
    }
    await _auth.signOut();
    _cachedUser = null;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}