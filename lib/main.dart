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

ValueNotifier<User?> userCredential = ValueNotifier(null);
FirebaseFunctions? firebaseFunctions;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Functions and store the instance globally
  firebaseFunctions = FirebaseFunctions.instanceFor(app: app);

  runApp(AppRoot());
}

// Top-level widget that rebuilds on auth state changes
class AppRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(onInitializationComplete: () {});
        }
        final user = snapshot.data;
        return MaterialApp(
          title: 'MatchBook',
          theme: appTheme,
          home: _routeForUser(user),
          routes: {
            '/first': (context) => FirstOpen(),
            '/auth': (context) => AuthenticationPage(),
            '/explore': (context) => HomePage(),
            '/setup': (context) => NewUserSetup(),
            '/settings': (context) => SettingsPage(),
            '/loading': (context) => LoadingPage(),
            '/authorDetails': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return AuthorDetailsPage(
                authorKey: args['authorKey'],
                authorName: args['authorName'],
              );
            },
          },
        );
      },
    );
  }
}

// Routing logic for user state
Widget _routeForUser(User? user) {
  if (user == null) {
    return AuthenticationPage();
  }
  // Use FutureBuilder to check Firestore user doc
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
    builder: (context, userDocSnapshot) {
      final doc = userDocSnapshot.data;
      if (doc == null || !doc.exists) {
        return Scaffold(
          backgroundColor: appTheme.colorScheme.primary,
          body: Center(
            child: Text('User data not found. Please try again later.',
                style: TextStyle(color: Colors.red)),
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
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      appBar: AppBar(),
      body: ValueListenableBuilder(
        valueListenable: userCredential,
        builder: (context, value, child) {
          return (userCredential.value == '' || userCredential.value == null)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(18, 160, 18, 78),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Read What You ',
                                  style: appTheme.textTheme.headlineLarge,
                                ),
                                TextSpan(
                                  text: 'Love',
                                  style: appTheme.textTheme.headlineLarge
                                      ?.copyWith(
                                    color: appTheme.colorScheme
                                        .secondary, // Change this to your desired color
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                              'Explore famous works of literature, from modern classics to ancient texts, with just a simple swipe.',
                              style: appTheme.textTheme.bodyLarge),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.arrow_forward),
                          iconAlignment: IconAlignment.end,
                          label: Text('Get started'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.colorScheme.secondary,
                            foregroundColor: appTheme.colorScheme.onSecondary,
                            textStyle: appTheme.textTheme.bodyMedium,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/first');
                          },
                        ),
                      )
                    ],
                  ),
                )
              : HomePage();
        },
      ),
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
    // Use a fade transition to MyHomePage
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MyHomePage(),
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
    // This branch is no longer needed, but kept for safety
    return MyHomePage();
  }
}
