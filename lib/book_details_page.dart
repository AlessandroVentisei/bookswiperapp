import 'package:bookswiperapp/functions/get_books.dart';
import 'package:bookswiperapp/widgets/book_cover_image.dart';
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
            if (book.data['isbn_13'] != null &&
                book.data['isbn_13'] is List &&
                (book.data['isbn_13'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: BookshopLinkButton(
                  title: book.title,
                  author: book.authors.join(", "),
                  isbn: (book.data['isbn_13'] as List)[0],
                ),
              ),
            if (book.subjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Subjects: ' + book.subjects.take(5).join(', '),
                  style: appTheme.textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
