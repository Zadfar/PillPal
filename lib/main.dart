import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mm_project/firebase_options.dart';
import 'package:mm_project/screens/home_screen.dart';
import 'package:mm_project/screens/login_screen.dart';
import 'package:mm_project/screens/profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkProfileExists(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    // Check if key profile fields exist (e.g., 'age' as a proxy for setup completion)
    return doc.exists && doc.data() != null && doc.data()!.containsKey('age');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PillPal",
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }

          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: _checkProfileExists(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (profileSnapshot.hasData && profileSnapshot.data!) {
                return const HomeScreen();
              }
              return const ProfileSetupScreen();
            },
          );
        },
      ),
    );
  }
}