import 'package:bookswiperapp/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookswiperapp/home.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:bookswiperapp/loading_page.dart';

class NewUserSetup extends StatefulWidget {
  const NewUserSetup({super.key});

  @override
  State<NewUserSetup> createState() => _NewUserSetupState();
}

class _NewUserSetupState extends State<NewUserSetup> {
  final List<String> genres = [
    'Fantasy',
    'Science Fiction',
    'Mystery',
    'Romance',
    'Thriller',
    'Historical',
    'Non-Fiction',
    'Biography',
    'Young Adult',
    'Children',
    'Horror',
    'Adventure',
    'Classic',
    'Poetry',
    'Drama',
    'Comics',
    'Self-Help',
    'Philosophy',
    'Spirituality',
    'Travel',
    'Humor',
  ];
  final Set<String> selectedGenres = {};

  void _onGenreTap(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else if (selectedGenres.length < 5) {
        selectedGenres.add(genre);
      }
    });
  }

  Future<void> _onNext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'subjectKeywords':
            selectedGenres.toList(), // Set keywords to selected genres
      });
      // Trigger fetching of books here.
      firebaseFunctions!.httpsCallable("fetchAndEnrichBooks").call({
        "userId": FirebaseAuth.instance.currentUser!.uid,
      });
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoadingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome', style: appTheme.textTheme.headlineMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick your favourite genres (up to 5):',
                  style: appTheme.textTheme.headlineMedium!.copyWith(
                    color: appTheme.colorScheme.primary,
                  ),
                ),
                Text(
                  'This will help us initial books to recommend.',
                  style: appTheme.textTheme.bodyMedium!.copyWith(
                    color: appTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 64),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: genres.map((genre) {
                final selected = selectedGenres.contains(genre);
                return ChoiceChip(
                  label: Text(genre),
                  selected: selected,
                  checkmarkColor: appTheme.colorScheme.onPrimary,
                  onSelected: (_) => _onGenreTap(genre),
                  selectedColor: appTheme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? appTheme.colorScheme.onPrimary
                        : appTheme.colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: selectedGenres.length >= 2 ? _onNext : null,
              child: Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedGenres.length >= 2
                    ? appTheme.colorScheme.primary
                    : Colors.grey,
                foregroundColor: selectedGenres.length >= 2
                    ? appTheme.colorScheme.onPrimary
                    : Colors.white,
                disabledBackgroundColor: Colors.grey,
                disabledForegroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
