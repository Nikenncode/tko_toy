// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';



import 'home_page.dart';
import 'login_page.dart';

import 'login_signup_page.dart';


const tkoOrange = Color(0xFFFF6A00);
const tkoCream  = Color(0xFFF7F2EC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TkoApp());
}

class TkoApp extends StatelessWidget {
  const TkoApp({super.key});


  static const bool useTabbedLogin = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKO Loyalty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: tkoOrange,
        scaffoldBackgroundColor: tkoCream,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // Show a lightweight splash while Firebase checks current user
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }


        if (snap.data != null) {
          return const HomePage();
        } else {
          return TkoApp.useTabbedLogin
              ? const LoginSignupPage()
              : const LoginSignupPage();
        }
      },
    );
  }
}
