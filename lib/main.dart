import 'package:bookswiperapp/authentication_page.dart';
import 'package:bookswiperapp/home.dart';
import 'package:flutter/material.dart';
import 'first_page.dart';
import 'theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

ValueNotifier<User?> userCredential = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
      userCredential.value = user;
    } else {
      print('User is signed in!');
      userCredential.value = user;
    }
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      home: MyHomePage(),
      routes: {
        '/first': (context) => FirstOpen(),
        '/auth': (context) => AuthenticationPage(),
      },
    );
  }
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
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.colorScheme.secondary,
                            foregroundColor: appTheme.colorScheme.onSecondary,
                            textStyle: appTheme.textTheme.bodyMedium,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/first');
                          },
                          child: Text('Go to First Page'),
                        ),
                      ),
                    ],
                  ),
                )
              : HomePage();
        },
      ),
    );
  }
}
