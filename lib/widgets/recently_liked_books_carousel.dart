import 'package:bookswiperapp/functions/get_books.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:bookswiperapp/theme/theme.dart';
import '../book_details_page.dart';

class RecentlyLikedBooksCarousel extends StatelessWidget {
  const RecentlyLikedBooksCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('likedBooks')
            .orderBy('createdAt', descending: true)
            .limit(15)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: RiveAnimation.asset(
                      '/Users/Alex/Desktop/FlutterDev/bookswiperapp/lib/assets/loading_book.riv',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      animations: const ['loading'],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("Go and explore...",
                      style: appTheme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: RiveAnimation.asset(
                      '/Users/Alex/Desktop/FlutterDev/bookswiperapp/lib/assets/loading_book.riv',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      animations: const ['loading'],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("Go and explore...",
                      style: appTheme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final book =
                  Book(docId: docs[index].id, data: docs[index].data());
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsPage(book: book),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          book.bookshopCoverUrl ??
                              (book.cover != 0
                                  ? 'https://covers.openlibrary.org/b/id/${book.cover}-L.jpg'
                                  : 'https://via.placeholder.com/100x150?text=No+Cover'),
                          height: 150,
                          width: 100,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Text(
                        book.title.isNotEmpty
                            ? book.title
                            : 'No title available...',
                        overflow: TextOverflow.ellipsis,
                        style: appTheme.textTheme.bodyMedium,
                      ),
                      Text(
                        (book.authors.isNotEmpty)
                            ? book.authors[0]
                            : 'Unknown Author',
                        overflow: TextOverflow.ellipsis,
                        style: appTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
