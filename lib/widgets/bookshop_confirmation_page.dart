import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookswiperapp/theme/theme.dart';

class BookshopConfirmationPage extends StatelessWidget {
  final String redirectUrl;
  const BookshopConfirmationPage({super.key, required this.redirectUrl});

  Future<void> _confirmAndGo(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'hasClickedBookshopLinkButton': true}, SetOptions(merge: true));
      }
      await launchUrl(Uri.parse(redirectUrl),
          mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open Bookshop.org. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Leaving MatchBook',
              style: appTheme.textTheme.headlineSmall)),
      backgroundColor: appTheme.colorScheme.primary,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Text(
              'Going to Bookshop.org',
              style: appTheme.textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            Text(
              'We are sending you to a partner website to get this book, thereby helping support independent bookshops and this app.',
              style: appTheme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'You may be asked for:',
              style: appTheme.textTheme.headlineMedium,
              textAlign: TextAlign.left,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.check,
                    size: 18, color: appTheme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bookshop.org login or to create an account.',
                    style: appTheme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.check,
                    size: 18, color: appTheme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment details upon checkout.',
                    style: appTheme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            Spacer(),
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Text(
                  'Find out more about bookshop.org: ',
                  style: appTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://uk.bookshop.org/pages/about'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Image.asset(
                      'lib/assets/bookshoporg_logo.png',
                      width: 160,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Take me there'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.colorScheme.secondary,
                  foregroundColor: appTheme.colorScheme.onSecondary,
                ),
                onPressed: () => _confirmAndGo(context),
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
