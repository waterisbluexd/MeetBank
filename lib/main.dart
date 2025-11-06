import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:meetbank/screens/HomePage.dart';
import 'package:meetbank/screens/LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive mode only for Android
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  if (kIsWeb) {
    // Web-specific Firebase initialization
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCPp5-fEmWXmJz2cFVxyXdZeFPiGiN70PE",
        authDomain: "meetbank-42b78.firebaseapp.com",
        projectId: "meetbank-42b78",
        storageBucket: "meetbank-42b78.appspot.com",
        messagingSenderId: "483409885225",
        appId: "1:483409885225:web:b8be92192e6f0c4391c438",
        measurementId: "G-86CWZP05PZ",
      ),
    );
  } else {
    // Android/iOS initialization (uses google-services.json)
    await Firebase.initializeApp();

    // Initialize Google Sign-In with server client ID for Android
    await GoogleSignIn.instance.initialize(
      serverClientId: "483409885225-epbnj2lsk86coqvsd7cv4sil7avm7u49.apps.googleusercontent.com",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MeetBank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}