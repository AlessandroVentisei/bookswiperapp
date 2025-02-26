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

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on Exception catch (e) {
      print('exception->$e');
    }
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
                    if (userCredential.value != null) {
                      print(userCredential.value);
                    }
                  },
                  child: Text("Continue with Google"),
                ),
                OutlinedButton(
                  onPressed: () => {},
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
                  onPressed: () => {},
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
