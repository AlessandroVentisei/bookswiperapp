import 'package:bookswiperapp/authentication_page.dart';
import 'package:bookswiperapp/explore_page.dart';
import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/main.dart';
import 'package:bookswiperapp/new_user_setup.dart';
import 'package:bookswiperapp/settings_page.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'widgets/recently_liked_books_carousel.dart';
import 'package:bookswiperapp/widgets/suggested_authors_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Container(
              width: double.infinity,
              child: Text(
                'MatchBook',
                style: appTheme.textTheme.headlineMedium,
              )),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
        backgroundColor: appTheme.colorScheme.primary,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                SizedBox(
                  height: 0,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExplorePage(),
                        ));
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    decoration: BoxDecoration(
                      color: appTheme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      spacing: 16,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          color: appTheme.colorScheme.primary,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Explore Books",
                              style: appTheme.textTheme.displayMedium!.copyWith(
                                color: appTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_right_outlined),
                      ],
                    ),
                  ),
                ),
                recommendedBooks(),
                const SuggestedAuthorsWidget(),
                favouriteGenres(),
                publishingPeriod(),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => AuthenticationPage()));
                  },
                  child: Text('Sign Out'),
                ),
                SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ));
  }

  Widget recommendedBooks() {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recently liked books",
          style: appTheme.textTheme.displayMedium,
        ),
        RecentlyLikedBooksCarousel(),
      ],
    );
  }
}

Widget favouriteGenres() {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(
      "Favorite Genres",
      style: appTheme.textTheme.displayMedium,
    ),
    StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Text("Error loading genres.");
        }
        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() != null) {
          final genres = (snapshot.data!.data()
              as Map<String, dynamic>)['subjectKeywords'] as List<dynamic>?;
          if (genres != null && genres.isNotEmpty) {
            return Wrap(
                spacing: 6,
                runSpacing: 4,
                children: genres.map((genre) {
                  return Text(
                    genre.toString() + ",",
                    style: appTheme.textTheme.bodyMedium,
                  );
                }).toList());
          } else {
            return Text("No favorite genres found.");
          }
        }
        return Text("No favorite genres found.");
      },
    ),
  ]);
}

Widget publishingPeriod() {
  return Column(
    spacing: 4,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Favourite Publishing Period",
        style: appTheme.textTheme.displayMedium,
      ),
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Text("Error loading genres.");
          }
          if (snapshot.hasData &&
              snapshot.data!.exists &&
              snapshot.data!.data() != null) {
            final user = snapshot.data!.data() as Map<String, dynamic>;
            final favouritePublishingPeriod =
                user['favouritePublishingPeriod'] as String?;
            if (favouritePublishingPeriod != null) {
              return Text(
                favouritePublishingPeriod,
                style: appTheme.textTheme.bodyMedium,
              );
            } else {
              return Text("No favorite publishing period found.");
            }
          }
          return Text("No favorite publishing period found.");
        },
      ),
    ],
  );
}
