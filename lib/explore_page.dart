import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/home.dart';
import 'package:bookswiperapp/main.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:math';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePage createState() => _ExplorePage();
}

class _ExplorePage extends State<ExplorePage> {
  int cardIndex = 0;
  bool isProcessingSwipe = false; // Add a flag to track ongoing calls

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void _onCardChanged(int newIndex) {
      cardIndex = newIndex;
    }

    Future<List<Book>> _loadBooks() async {
      return await getBooks(FirebaseAuth.instance.currentUser!);
    }

    return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 10,
          elevation: 0,
          shadowColor: Colors.black45,
          title: Text(
            'Explore',
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
                height: 400, // Fixed height for the card
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: appTheme.colorScheme.primary),
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  child: Column(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Set a fixed height for the image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 356,
                          height: 522,
                          child: Image.network(
                            'https://covers.openlibrary.org/b/id/${book.coverI}-L.jpg',
                            width: 356,
                            height: 522,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: appTheme.colorScheme.secondary,
                                  backgroundColor:
                                      appTheme.colorScheme.secondary,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Column(
                        spacing: 6,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: appTheme.textTheme.headlineMedium,
                            overflow: TextOverflow.fade,
                          ),
                          Text(
                            book.authors.join(", "),
                            style: appTheme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Text(book.description,
                          style: appTheme.textTheme.bodyMedium)
                    ],
                  ),
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
                    numberOfCardsDisplayed: 2,
                    backCardOffset: Offset(0, 40),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    scale: 1.0,
                    onSwipe: (previousIndex, currentIndex, direction) async {
                      if (direction == CardSwiperDirection.right) {
                        try {
                          firebaseFunctions!.httpsCallable("likeBook").call({
                            "book": books[previousIndex].docId,
                            "user": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Book Liked");
                          firebaseFunctions!.httpsCallable("fetchBooks").call({
                            "user": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Books fetched");
                          return true;
                        } catch (e) {
                          print("Error liking book: $e");
                        }
                      } else if (direction == CardSwiperDirection.left) {
                        try {
                          firebaseFunctions!.httpsCallable("dislikeBook").call({
                            "book": books[previousIndex].docId,
                            "user": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Book disliked");
                          firebaseFunctions!.httpsCallable("fetchBooks").call({
                            "user": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Books fetched");
                          return true;
                        } catch (e) {
                          print("Error liking book: $e");
                        }
                      }
                      return true;
                    },
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
        ));
  }
}
