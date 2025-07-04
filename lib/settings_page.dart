import 'package:flutter/material.dart';
import 'package:bookswiperapp/theme/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: appTheme.textTheme.headlineMedium),
      ),
      body: Center(
        child: Text(
          'Settings go here!',
          style: appTheme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
