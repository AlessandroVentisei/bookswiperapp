import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rive/rive.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  const SplashScreen({Key? key, required this.onInitializationComplete})
      : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate initialization delay
    Future.delayed(const Duration(seconds: 2), () {
      widget.onInitializationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: RiveAnimation.asset(
                'lib/assets/loading_book.riv',
                fit: BoxFit.contain,
                animations: const ['loading'],
              ),
            ),
            Text('MatchBook', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
