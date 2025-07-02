import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:bookswiperapp/widgets/author_widget.dart';
import 'package:bookswiperapp/widgets/bookshop_link_button.dart';

class BookDetailsPage extends StatelessWidget {
  final Map<String, dynamic> book;
  const BookDetailsPage({super.key, required this.book});
  @override
  Widget build(BuildContext context) {
    print(book["description"]);
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
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book['cover_id'] != null
                      ? 'https://covers.openlibrary.org/b/id/${book['cover_id']}-L.jpg'
                      : 'https://picsum.photos/200/300',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              book['title'] ?? 'No title available...',
              style: appTheme.textTheme.headlineMedium,
            ),
            if (book['authors'] != null &&
                book['authors'] is List &&
                book['authors'].isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (book['authors'] as List)
                    .where((author) =>
                        author['details'] != null &&
                        author['details']['name'] != null &&
                        author['key'] != null)
                    .toSet()
                    .map<Widget>((author) => AuthorWidget(
                          authorName: author['details']['name'],
                          authorKey: author['key'],
                        ))
                    .toList(),
              ),
            if (book['publish_date'] != null)
              Text('Published: ${book['publish_date']}',
                  style: appTheme.textTheme.bodySmall),
            if (book['description'] != null &&
                book['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  book['description'] is String
                      ? book['description']
                      : (book['description']['value'] ?? ''),
                  style: appTheme.textTheme.bodyMedium,
                ),
              ),
            if (book['isbn_13'] != null &&
                book['isbn_13'] is List &&
                book['isbn_13'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: BookshopLinkButton(
                  title: book['title'],
                  isbn: book['isbn_13'][0],
                ),
              ),
            if (book['subject'] != null && book['subject'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Subjects: ' + (book['subject'] as List).take(5).join(', '),
                  style: appTheme.textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
