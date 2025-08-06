import 'package:bookswiperapp/functions/user_checks.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  @override

  Future<dynamic> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);
      // if user logs in for the first time, setup a new user document
      if (user.additionalUserInfo?.isNewUser ?? false) {
        await setupNewUser(user.user!);
      }
    } on Exception catch (e) {
      print('exception->$e');
    }
  }

  Future<dynamic> signInWithApple() async {
    try {
      final AuthProvider appleProvider = AppleAuthProvider();
      UserCredential user = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      // if user logs in for the first time, setup a new user document
      if (user.additionalUserInfo?.isNewUser ?? false) {
        await setupNewUser(user.user!);
      }
    } on Exception catch (e) {
      print('exception->$e');
    }
  }

  Future<dynamic> _showEmailAuthDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';
    String? errorMessage;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          style: appTheme.textTheme.headlineMedium!.copyWith(
                            color: appTheme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          style: appTheme.textTheme.headlineSmall!.copyWith(
                            color: appTheme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(labelText: 'Email'),
                          onChanged: (val) => email = val,
                          validator: (val) => val != null && val.contains('@')
                              ? null
                              : 'Enter a valid email',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          style: appTheme.textTheme.headlineSmall!.copyWith(
                            color: appTheme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          onChanged: (val) => password = val,
                          validator: (val) => val != null && val.length >= 6
                              ? null
                              : 'Min 6 characters',
                        ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(errorMessage!,
                                style: TextStyle(
                                    color: appTheme.colorScheme.error)),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: () async {
                                try {
                                  UserCredential user = await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(email: email, password: password);
                                  await setupNewUser(user.user!);
                                  await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(email: email, password: password);
                                  setState(() => errorMessage = null);
                                  Navigator.of(context).pop();
                                } on FirebaseAuthException catch (e) {
                                  setState(() => errorMessage = e.message);
                                }
                              },
                              child: Text('Create account'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (formKey.currentState?.validate() != true) {
                                  return;
                                }
                                try {
                                  await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(email: email, password: password);
                                  setState(() => errorMessage = null);
                                  Navigator.of(context).pop();

                                } on FirebaseAuthException catch (e) {
                                  setState(() => errorMessage = e.message);
                                }
                              },
                              child: Text('Login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 150, 18, 21),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              "Welcome.",
              style: appTheme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await signInWithGoogle();
                    setState(() {
                      print("Google sign in completed");
                    });
                  },
                  child: Text("Continue with Google"),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await signInWithApple();
                    setState(() {
                      print("Apple sign in completed");
                    });
                  },
                  child: Text("Continue with Apple"),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Divider(
                        color: appTheme.colorScheme.surface,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "Or",
                        style: appTheme.textTheme.bodyLarge!.copyWith(
                          color: appTheme.colorScheme.surface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: appTheme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _showEmailAuthDialog(context);
                    setState(() {
                      print("Email sign in completed");
                    });
                  },
                  child: Text("Login with email"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
