import 'package:flutter/material.dart';
import 'first_page.dart';
import 'theme/theme.dart';

void main() {
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
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text('Read What You Love', style: appTheme.textTheme.headlineLarge),
            Text(
                'Explore famous works of literature, from modern classics to ancient texts, with just a simple swipe.',
                style: appTheme.textTheme.bodyLarge),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/first');
              },
              child: Text('Go to First Page'),
            ),
          ],
        ),
      ),
    );
  }
}
