import 'dart:async';

import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/home.dart';
import 'package:bookswiperapp/main.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:rive/rive.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/author_widget.dart';
import 'package:bookswiperapp/widgets/bookshop_link_button.dart';
import 'widgets/book_cover_image.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePage createState() => _ExplorePage();
}

class _ExplorePage extends State<ExplorePage> {
  int cardIndex = 0;
  List<Book> _books = [];
  bool isProcessingSwipe = false; // Add a flag to track ongoing calls
  StreamSubscription<List<Book>>? _booksSubscription;

  // Stream to listen to real-time updates from Firestore
  Stream<List<Book>> _booksStream() {
    final user = FirebaseAuth.instance.currentUser!;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .orderBy('index', descending: false);
    return userRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Book.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  @override
  void initState() {
    super.initState();
    _booksSubscription = _booksStream().listen((booksFromFirestore) {
      setState(() {
        _books = booksFromFirestore;
      });
    });
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void _onCardChanged(int newIndex) {
      cardIndex = newIndex;
    }

    final CardSwiperController _swiperController = CardSwiperController();
    List<Book>? _previousBooks;

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
        body: StreamBuilder<List<Book>>(
          stream: _booksStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print('Error in StreamBuilder: \\${snapshot.error}');
              return Center(
                  child: Text('Error loading books. Please try again.'));
            } else if (_books.isEmpty) {
              firebaseFunctions!.httpsCallable("fetchAndEnrichBooks").call({
                "userId": FirebaseAuth.instance.currentUser!.uid,
              });
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 150,
                        height: 150,
                        child: RiveAnimation.asset(
                          '/Users/Alex/Desktop/FlutterDev/bookswiperapp/lib/assets/loading_book.riv',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          animations: const ['loading'],
                        )),
                    Text("Finding more books for you...",
                        style: appTheme.textTheme.bodyLarge),
                  ],
                ),
              );
            }

            List<Container> cards = _books.map((book) {
              return Container(
                  height: 400, // Fixed height for the card
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: appTheme.colorScheme.primary),
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
                              child: BookCoverImage(
                                book: book,
                              ),
                            ),
                          ),
                          Column(
                            spacing: 6,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(
                                    book.title,
                                    style: appTheme.textTheme.headlineMedium,
                                    overflow: TextOverflow.fade,
                                  ),
                                  Text(book.data["publish_date"] ?? '',
                                      style: appTheme.textTheme.bodyMedium),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: book.authors
                                    .where((author) =>
                                        author["details"] != null &&
                                        author["details"]["name"] != null &&
                                        author["key"] != null)
                                    .toSet()
                                    .map((author) => AuthorWidget(
                                          authorName: author["details"]["name"],
                                          authorKey: author["key"],
                                        ))
                                    .toList(),
                              ),
                              if (book.description.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  book.description,
                                  style: appTheme.textTheme.bodyMedium,
                                ),
                              ],
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: BookshopLinkButton(
                                  title: book.title,
                                  isbn: (book.data['isbn_13'] is List &&
                                          book.data['isbn_13'].isNotEmpty)
                                      ? book.data['isbn_13'][0]
                                      : (book.data['isbn_13'] ?? null),
                                ),
                              ),
                              Text(
                                "Subjects: ${book.subjects.toString().replaceAll("[", "").replaceAll("]", "")}",
                              )
                            ],
                          ),
                        ]),
                  ));
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: CardSwiper(
                    controller: _swiperController, // Add this line
                    cardsCount: _books.length,
                    numberOfCardsDisplayed: 2,
                    backCardOffset: Offset(0, 40),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    scale: 1.0,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      if (direction == CardSwiperDirection.right) {
                        try {
                          firebaseFunctions!.httpsCallable("likeBook").call({
                            "book": _books[previousIndex].docId,
                            "user": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Book Liked");
                          firebaseFunctions!
                              .httpsCallable("fetchAndEnrichBooks")
                              .call({
                            "userId": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Books fetched");
                          return true;
                        } catch (e) {
                          print("Error liking book: $e");
                        }
                      } else if (direction == CardSwiperDirection.left) {
                        try {
                          firebaseFunctions!.httpsCallable("dislikeBook").call({
                            "book": _books[previousIndex].docId,
                            "user": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Book disliked");
                          firebaseFunctions!
                              .httpsCallable("fetchAndEnrichBooks")
                              .call({
                            "userId": FirebaseAuth.instance.currentUser!.uid,
                          });
                          print("Books fetched");
                          return true;
                        } catch (e) {
                          print("Error liking book: $e");
                        }
                      }
                      setState(() {
                        _books.removeAt(previousIndex);
                      });
                      return true;
                    },
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      return cards[index + 1];
                    },
                  ),
                );
              },
            );
          },
        ));
  }
}
