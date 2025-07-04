import 'package:bookswiperapp/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookshopLinkButton extends StatelessWidget {
  final String? title;
  final String? isbn;
  final String? format;
  const BookshopLinkButton({super.key, this.title, this.isbn, this.format});

  @override
  Widget build(BuildContext context) {
    final url =
        'https://uk.bookshop.org/search?affiliate=15242&keywords=${title?.replaceAll(' ', '+') ?? ''}&isbn=$isbn';
    if (format == 'small') {
      return IconButton(
        icon: Icon(
          Icons.open_in_new,
          size: 16,
        ),
        style: IconButton.styleFrom(
          backgroundColor: appTheme.colorScheme.secondary,
        ),
        onPressed: () {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      );
    }
    return ElevatedButton.icon(
      icon: Icon(Icons.open_in_new),
      label: Text('Find on Bookshop.org'),
      onPressed: () {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
    );
  }
}
