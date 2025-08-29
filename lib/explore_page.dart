import 'dart:async';

import 'package:bookswiperapp/functions/explore_books.dart';
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
  List<Book> _backupBooks = [];
  bool isProcessingSwipe = false;
  DocumentSnapshot? _lastDoc;
  bool _endOfBooks = false;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _batchSize = 10;
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _fetchInitBatch();
  }

  Future<void> _fetchInitBatch() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    var prevIndex = cardIndex;
    final books = await fetchBooks(
      batchSize: _batchSize * 2, // Fetch double the batch size for preloading
      lastDoc: null, // fresh start
    );
    // set backup books to the last 10 books fetched and the first half of the books to the main queue.
    if (books.isEmpty) {
      setState(() {
        _hasMore = false;
        _endOfBooks = true;
      });
      return;
    }

    if (books.length >= _batchSize) {
      setState(() {
        // Clear and replace main and backup queues
        _backupBooks = books.sublist(books.length ~/ 2);
        _books = books.sublist(0, books.length ~/ 2);
      });

      // Update _lastDoc
      final lastDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('books')
          .doc(books.last.docId);
      _lastDoc = await lastDocRef.get();
      // check that index is not out of bounds
      if (prevIndex >= _books.length - 1) {
        prevIndex = 0;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _swiperController.moveTo(prevIndex);
      });
    } else {
      setState(() => _hasMore = false);
      // Optionally trigger a callable function to fetch more books from backend
      await firebaseFunctions!.httpsCallable("fetchAndEnrichBooks").call({
        "userId": FirebaseAuth.instance.currentUser!.uid,
      });
      _waitForBooksAndReload();
    }

    setState(() => _isLoading = false);
  }

  

  Future<void> _fetchBackupBooks() async {
    final newBooks = await fetchBooks(batchSize: 10, lastDoc: _lastDoc);
    setState(() {
      _backupBooks.addAll(newBooks);
    });
    // if newBooks are less than 10 the we will need to trigger a new
    // fetchAndEnrichBooks callable to get more books.

    if (newBooks.length < 10) {
      await firebaseFunctions!.httpsCallable("fetchAndEnrichBooks").call({
        "userId": FirebaseAuth.instance.currentUser!.uid,
      });
    }
  }
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _waitForBooksAndReload() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userBooksRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('books');

    // Checking every 2 seconds for a max of 90 seconds
    for (int i = 0; i < 45; i++) {
      final snapshot = await userBooksRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print("Books are now available!");
        setState(() {
          _hasMore = true;
        });
        await _fetchInitBatch();
        return;
      }
      await Future.delayed(Duration(seconds: 2));
    }

    print("Still no books after waiting.");
  }

  @override
  Widget build(BuildContext context) {

    if (_books.isEmpty && _isLoading) {
      return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 10,
          elevation: 0,
          shadowColor: Colors.black45,
          title: Text('Explore', style: appTheme.textTheme.headlineMedium),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context, MaterialPageRoute(builder: (context) => HomePage()));
            },
          ),
        ),
        backgroundColor: appTheme.colorScheme.primary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 150,
                    height: 150,
                    child: RiveAnimation.asset(
                      'lib/assets/loading_book.riv',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      animations: const ['loading'],
                    )),
                Text(
                  "Finding more books for you...",
                  style: appTheme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "This may take a moment as we search deep in the catalogues of OpenLibrary.org",
                  style: appTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Container> cards = _books.map((book) {
      return Container(
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
                          Text(book.data["publish_date"] ?? '', style: appTheme.textTheme.bodyMedium),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: book.authors
                            .where((author) =>
                                author["details"] != null && author["details"]["name"] != null && author["key"] != null)
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
                          isbn: (book.data['isbn_13'] is List && book.data['isbn_13'].isNotEmpty)
                              ? book.data['isbn_13'][0]
                              : (book.data['isbn_13'] ?? null),
                        ),
                      ),
                      Text(
                        "Subjects: " + book.subjects.toString().replaceAll("[", "").replaceAll("]", ""),
                      )
                    ],
                  ),
                ]),
          ));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 10,
        elevation: 0,
        shadowColor: Colors.black45,
        title: Text('Explore', style: appTheme.textTheme.headlineMedium),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ),
      backgroundColor: appTheme.colorScheme.primary,
      body: (_books.isEmpty || _books.length < 2)
          ? Center(child: Text('No books available.'))
          : Column(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                child: CardSwiper(
                  isLoop: true,
                  controller: _swiperController,
                  cardsCount: _books.length,
                  numberOfCardsDisplayed: 3,
                  backCardOffset: Offset(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  scale: 1.0,
                  onSwipe: (previousIndex, currentIndex, direction) {
                    print(
                        'onSwipe called: previousIndex=$previousIndex, current index =$currentIndex, direction=$direction');
                    if (direction == CardSwiperDirection.right) {
                      try {
                        firebaseFunctions!.httpsCallable("likeBook").call({
                          "book": _books[previousIndex].docId,
                          "user": FirebaseAuth.instance.currentUser!.uid,
                        });
                        print("Book Liked");
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
                      } catch (e) {
                        print("Error disliking book: $e");
                      }
                    }
                    // Mark the book as swiped
                    _books[previousIndex].wasSwiped = true;
                    if (_backupBooks.isNotEmpty) {
                      setState(() {
                        _books[previousIndex] = _backupBooks.removeAt(0);
                      });
                      if (_backupBooks.length < 5) _fetchBackupBooks();
                    } else {
                      // Show loading card/message
                      _endOfBooks = true;
                      print("No backup books available, showing loading card.");
                    }
                    return true;
                  },
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    if (!_endOfBooks) {
                      return cards[index];
                    } else {
                      return Container(
                        height: double.infinity,
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: appTheme.colorScheme.primary),
                        child: Center(
                          child: Text(
                            "No more books available. Please check back later.",
                            style: appTheme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                decoration: BoxDecoration(
                    color: appTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Centered main buttons
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            spacing: 32,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _swiperController
                                      .swipe(CardSwiperDirection.left);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(12),
                                  backgroundColor:
                                      appTheme.colorScheme.secondary,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 42,
                                  color: appTheme.colorScheme.primary,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _swiperController
                                      .swipe(CardSwiperDirection.right);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(12),
                                  backgroundColor:
                                      appTheme.colorScheme.secondary,
                                ),
                                child: Icon(
                                  Icons.favorite_border_rounded,
                                  size: 42,
                                  color: appTheme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Left-aligned redo button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: () {
                              _swiperController.undo();
                            },
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(8),
                              backgroundColor: appTheme.colorScheme.onPrimary,
                            ),
                            child: Icon(
                              Icons.replay_rounded,
                              size: 24,
                              color: appTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
    );
  }
}
