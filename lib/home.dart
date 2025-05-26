import 'package:bookswiperapp/explore_page.dart';
import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/main.dart';
import 'package:bookswiperapp/new_user_setup.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    labelText: 'Authors, Titles, or Subjects',
                  ),
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
                suggestedAuthors(),
                favouriteGenres(),
                publishingPeriod(),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: Text('Sign Out'),
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
          "Recommended Books",
          style: appTheme.textTheme.displayMedium,
        ),
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        'https://picsum.photos/200/300',
                        height: 150,
                        width: 100,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Text(
                      'Book Title which is longer than the author',
                      overflow: TextOverflow.ellipsis,
                      style: appTheme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Author which is quite long',
                      overflow: TextOverflow.ellipsis,
                      style: appTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget suggestedAuthors() {
  return Column(
    spacing: 10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Suggested Authors",
        style: appTheme.textTheme.displayMedium,
      ),
      Container(
        height: 125,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 10,
          itemBuilder: (context, index) {
            return Container(
              width: 100,
              margin: const EdgeInsets.fromLTRB(0, 0, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      'https://picsum.photos/200/300',
                      height: 100,
                      width: 100,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Text(
                    'George Orwell',
                    overflow: TextOverflow.ellipsis,
                    style: appTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget favouriteGenres() {
  return Column(
    spacing: 4,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Favorite Genres",
        style: appTheme.textTheme.displayMedium,
      ),
      Text("Genres here"),
    ],
  );
}

Widget publishingPeriod() {
  return Column(
    spacing: 4,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Publishing Period",
        style: appTheme.textTheme.displayMedium,
      ),
      Text("1924 - 1949"),
    ],
  );
}
