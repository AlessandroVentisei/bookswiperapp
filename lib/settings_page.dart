import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _deleteUserData(BuildContext context, String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);

    final subcollectionNames = [
      'likedBooks',
      'dislikedBooks',
      'books'
    ]; // Replace with your actual subcollection names
    for (final subcolName in subcollectionNames) {
      final subcol = userDoc.collection(subcolName);
      final snapshots = await subcol.get();
      for (final doc in snapshots.docs) {
        await doc.reference.delete();
      }
    }
    // Delete the user document
    await userDoc.delete();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _deleteUserData(context, user.uid);
      await user.delete();
      Navigator.of(context).pop(); // Remove progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully.')),
      );
      Navigator.of(context).pop(); // Go back to previous screen
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Remove progress dialog
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please re-authenticate to delete your account.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: e.message}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Remove progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: appTheme.textTheme.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Account',
                style: appTheme.textTheme.displayMedium!.copyWith(
                  color: appTheme.colorScheme.primary,
                )),
          ),
          const SizedBox(height: 4),
          Column(
            children: [
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                selected: true,
                style: ListTileStyle.list,
                selectedColor: appTheme.colorScheme.surface,
                selectedTileColor: appTheme.colorScheme.surface,
                splashColor: appTheme.colorScheme.primary.withOpacity(0.3),
                title: Text(
                  'Rate this app',
                  style: appTheme.textTheme.displaySmall!.copyWith(
                    color: appTheme.colorScheme.primary,
                  ),
                ),
                leading:
                    Icon(Icons.star_rate, color: appTheme.colorScheme.primary),
                onTap: () async {
                  // Replace with your actual app store URLs
                  final iosUrl =
                      Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');
                  final androidUrl = Uri.parse(
                      'https://play.google.com/store/apps/details?id=YOUR.PACKAGE.NAME');
                  final url = Theme.of(context).platform == TargetPlatform.iOS
                      ? iosUrl
                      : androidUrl;
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open the app store.')),
                    );
                  }
                },
              ),
              ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                selected: true,
                style: ListTileStyle.list,
                selectedColor: appTheme.colorScheme.surface,
                selectedTileColor: appTheme.colorScheme.surface,
                splashColor: appTheme.colorScheme.primary.withOpacity(0.3),
                leading: Icon(Icons.delete_forever,
                    color: appTheme.colorScheme.primary),
                title: Text(
                  'Delete Account',
                  style: appTheme.textTheme.displaySmall!.copyWith(
                    color: appTheme.colorScheme.primary,
                  ),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Account',
                          style: appTheme.textTheme.displayMedium!.copyWith(
                            color: appTheme.colorScheme.primary,
                          )),
                      content: Text(
                          'Are you sure you want to delete your account? This action cannot be undone so be careful!',
                          style: appTheme.textTheme.displaySmall!.copyWith(
                            color: appTheme.colorScheme.primary,
                          )),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _deleteAccount(context);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Email the developer',
                style: appTheme.textTheme.displayMedium!.copyWith(
                  color: appTheme.colorScheme.primary,
                )),
          ),
          SizedBox(height: 4),
          Column(children: [
            ListTile(
              titleAlignment: ListTileTitleAlignment.center,
              selected: true,
              style: ListTileStyle.list,
              selectedColor: appTheme.colorScheme.surface,
              selectedTileColor: appTheme.colorScheme.surface,
              splashColor: appTheme.colorScheme.primary.withOpacity(0.3),
              title: Text(
                'alessandro.ventisei@outlook.com',
                style: appTheme.textTheme.displaySmall!.copyWith(
                  color: appTheme.colorScheme.primary,
                ),
              ),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'alessandro.ventisei@outlook.com',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open email client.')),
                  );
                }
              },
            )
          ]),
        ],
      ),
    );
  }
}
