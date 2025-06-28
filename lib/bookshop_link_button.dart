import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookshopLinkButton extends StatelessWidget {
  final String? title;
  final String? isbn;
  const BookshopLinkButton({super.key, this.title, this.isbn});

  @override
  Widget build(BuildContext context) {
    if (isbn == null || isbn!.isEmpty) return SizedBox.shrink();
    final url =
        'https://uk.bookshop.org/search?affiliate=15242&keywords=${title?.replaceAll(' ', '+') ?? ''}&isbn=$isbn';
    return ElevatedButton.icon(
      icon: Icon(Icons.open_in_new),
      label: Text('Find on Bookshop.org'),
      onPressed: () {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
    );
  }
}
