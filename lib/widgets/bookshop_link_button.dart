import 'package:bookswiperapp/theme/theme.dart';
import 'package:bookswiperapp/widgets/bookshop_confirmation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookshopLinkButton extends StatelessWidget {
  final String? title;
  final String? author;
  final String? isbn;
  final String? format;
  const BookshopLinkButton(
      {super.key,
      required this.title,
      required this.author,
      this.isbn,
      this.format});

  Future<void> _handlePress(BuildContext context, String url) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      bool hasClicked = false;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        hasClicked =
            data != null && data['hasClickedBookshopLinkButton'] == true;
      }

      if (hasClicked) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookshopConfirmationPage(redirectUrl: url),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keywords = ('$title $author').trim().replaceAll(' ', '+');
    final url =
        'https://uk.bookshop.org/search?affiliate=15242&keywords=$keywords&isbn=${isbn ?? ''}';

    if (format == 'small') {
      return IconButton(
        icon: const Icon(
          Icons.open_in_new,
          size: 16,
        ),
        style: IconButton.styleFrom(
          backgroundColor: appTheme.colorScheme.secondary,
          foregroundColor: appTheme.colorScheme.onSecondary,
        ),
        onPressed: () => _handlePress(context, url),
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.open_in_new),
      label: const Text('Buy'),
      style: OutlinedButton.styleFrom(
        foregroundColor: appTheme.colorScheme.onPrimary,
        side: BorderSide(color: Colors.transparent),
      ),
      onPressed: () => _handlePress(context, url),
    );
  }
}
