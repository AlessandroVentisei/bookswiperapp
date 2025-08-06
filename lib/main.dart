import 'package:bookswiperapp/authentication_page.dart';
import 'package:bookswiperapp/home.dart';
import 'package:bookswiperapp/new_user_setup.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'first_page.dart';
import 'theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './functions/user_checks.dart';
import 'splash_screen.dart';
import 'author_details_page.dart';
import 'settings_page.dart';
import 'loading_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFunctions? firebaseFunctions;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Functions and store the instance globally
  firebaseFunctions = FirebaseFunctions.instanceFor(app: app);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatchBook',
      theme: appTheme,
      home: AppRoot(), // AppRoot handles auth logic and returns the correct page
    );
  }
}

class AppRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        print(authSnapshot.connectionState);
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(onInitializationComplete: () {});
        }

        final user = authSnapshot.data;
        print("User: ${user?.uid}");
        return user == null
          ? AuthenticationPage()
          : FutureBuilder<DocumentSnapshot>(
              future: _ensureUserDoc(user),
              builder: (context, userDocSnapshot) {
                if (userDocSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return LoadingPage();
                }
                if (userDocSnapshot.hasError) {
                  return Scaffold(
                    backgroundColor: appTheme.colorScheme.primary,
                    body: Center(
                      child: Text(
                        'Error loading user data.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                final doc = userDocSnapshot.data;
                if (doc == null || !doc.exists) {
                  return Scaffold(
                    backgroundColor: appTheme.colorScheme.primary,
                    body: Center(
                      child: Text(
                        'User data not found. Please try again later.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (doc['isNewUser'] == true) {
                  print("New user detected, navigating to setup.");
                  return NewUserSetup();
                }
                print("Returning HomePage for existing user.");
                return HomePage();
              },
            );
          },
        );
      }
}

class SplashScreenWrapper extends StatefulWidget {
  @override
  _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _initialized = false;

  void _onInitializationComplete() {
    // Use a fade transition to AppRoot
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AppRoot(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return SplashScreen(onInitializationComplete: _onInitializationComplete);
    }
    return AppRoot();
  }
}

// Ensures user doc exists, runs setupNewUser if not, and returns the doc
Future<DocumentSnapshot> _ensureUserDoc(User user) async {
  final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
  final doc = await docRef.get();
  if (!doc.exists) {
    await setupNewUser(user);
    return await docRef.get();
  }
  return doc;
}
