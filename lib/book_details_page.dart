import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/widgets/book_cover_image.dart';
import 'package:bookswiperapp/widgets/get_Ai_summary.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:bookswiperapp/widgets/author_widget.dart';
import 'package:bookswiperapp/widgets/bookshop_link_button.dart';

class BookDetailsPage extends StatelessWidget {
  final Book book;
  const BookDetailsPage({super.key, required this.book});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Details',
          style: appTheme.textTheme.headlineMedium,
        ),
      ),
      backgroundColor: appTheme.colorScheme.primary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: BookCoverImage(book: book)),
            const SizedBox(height: 16),
            Text(
              book.title.isNotEmpty ? book.title : 'No title available...',
              style: appTheme.textTheme.headlineMedium,
            ),
            if (book.authors.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: book.authors
                    .map<Widget>((author) => AuthorWidget(
                        authorName: author["name"], authorKey: author["key"]))
                    .toList(),
              ),
            if (book.data['publish_date'] != null)
              Text('Published: ${book.data['publish_date']}',
                  style: appTheme.textTheme.bodySmall),
            if (book.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  book.description,
                  style: appTheme.textTheme.bodyMedium,
                ),
              ),
            SizedBox(
              height: 12,
            ),
            Row(
              spacing: 12,
              children: [
                aiSummaryButton(
                  bookDocId: book.docId,
                  bookKey: book.data['key'],
                  title: book.title,
                  author: book.authors!.isNotEmpty
                      ? book.authors![0]["name"] ?? ''
                      : '',
                ),
                BookshopLinkButton(
                    title: book.title, author: book.authors.join(", ")),
              ],
            ),
            if (book.reason_for_recommendation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  book.reason_for_recommendation,
                  style: appTheme.textTheme.bodyMedium,
                ),
              ),
            SizedBox(
              height: 32,
            ),
          ],
        ),
      ),
    );
  }
}
