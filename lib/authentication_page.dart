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
  ValueNotifier userCredential = ValueNotifier('');

  Future<dynamic> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential user =
          await FirebaseAuth.instance.signInWithCredential(credential);
      FirebaseAuth.instance.signInWithCredential(user.credential!);
    } on Exception catch (e) {
      print('exception->$e');
    }
  }

  Future<dynamic> signInWithApple() async {
    try {
      final AuthProvider appleProvider = AppleAuthProvider();
      UserCredential user =
          await FirebaseAuth.instance.signInWithProvider(appleProvider);
      FirebaseAuth.instance.signInWithCredential(user.credential!);
    } on Exception catch (e) {
      print('exception->$e');
    }
  }

  Future<void> _showEmailAuthDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';
    bool isLogin = true;
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
                          isLogin ? 'Login' : 'Register',
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
                              onPressed: () async => {
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                        email: email, password: password)
                              },
                              child: Text('Create account'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (formKey.currentState?.validate() != true)
                                  return;
                                try {
                                  if (isLogin) {
                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                            email: email, password: password);
                                  }
                                  if (context.mounted)
                                    Navigator.pop(context, true);
                                } on FirebaseAuthException catch (e) {
                                  setState(() => errorMessage = e.message);
                                }
                              },
                              child: Text(isLogin ? 'Login' : 'Register'),
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
                    userCredential.value = await signInWithGoogle();
                    setState(() {
                      print("Google sign in completed");
                    });
                  },
                  child: Text("Continue with Google"),
                ),
                OutlinedButton(
                  onPressed: () async {
                    userCredential.value = await signInWithApple();
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
                  onPressed: () => _showEmailAuthDialog(context),
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
