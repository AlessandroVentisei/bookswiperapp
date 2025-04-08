import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/home.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:math';

class NewUserSetup extends StatefulWidget {
  const NewUserSetup({super.key});

  @override
  _NewUserSetup createState() => _NewUserSetup();
}

class _NewUserSetup extends State<NewUserSetup> {
  int cardIndex = 0;

  Future<List<Book>> _loadBooks() async {
    return await getBooks(FirebaseAuth.instance.currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    void _onCardChanged(int newIndex) {
      cardIndex = newIndex;
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 10,
        elevation: 0,
        shadowColor: Colors.black45,
        title: Text(
          'Explore Books',
          style: appTheme.textTheme.headlineMedium,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          },
        ),
      ),
      backgroundColor: appTheme.colorScheme.primary,
      body: FutureBuilder<List<Book>>(
        future: _loadBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error in FutureBuilder: ${snapshot.error}');
            return Center(
                child: Text('Error loading books. Please try again.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No books available. Please check back later.'));
          }

          List<Book> books = snapshot.data!;
          List<Container> cards = books.map((book) {
            return Container(
              height: 600,
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  stops: [0, 1.0],
                  colors: [Color(0xFF252525), Color(0xFF1E1E1E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      constraints: BoxConstraints.expand(width: 60, height: 60),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(65, 140, 140, 140),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '👍',
                        style: TextStyle(fontSize: 24),
                      )),
                  Text(book.title, style: appTheme.textTheme.headlineMedium),
                  Text(
                      book.subjects.isNotEmpty
                          ? 'Subjects: ${book.subjects.join(', ')}'
                          : 'No subjects available',
                      style: appTheme.textTheme.bodyLarge),
                ],
              ),
            );
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: CardSwiper(
                  cardsCount: cards.length,
                  cardBuilder:
                      (context, index, percentThresholdX, percentThresholdY) {
                    _onCardChanged(index);
                    return cards[index];
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
