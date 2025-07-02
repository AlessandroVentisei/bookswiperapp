import 'package:flutter/material.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:rive/rive.dart';
import '../functions/get_books.dart';

class BookCoverImage extends StatelessWidget {
  final Book book; // Accepts any book object with bookshop_cover_url and cover
  const BookCoverImage({super.key, required this.book});
  @override
  Widget build(BuildContext context) {
    print(book.bookshopCoverUrl);
    String? bookshopCoverUrl = book.bookshopCoverUrl ?? book.bookshopCoverUrl;
    String? coverId = book.cover.toString();
    String? imageUrl = (bookshopCoverUrl != null && bookshopCoverUrl.isNotEmpty)
        ? bookshopCoverUrl
        : (coverId.isNotEmpty)
            ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
            : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 356,
        height: 522,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                width: 356,
                height: 522,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: RiveAnimation.asset(
                      '/Users/Alex/Desktop/FlutterDev/bookswiperapp/lib/assets/loading_book.riv',
                      fit: BoxFit.contain,
                      animations: const ['loading'],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // fallback to OpenLibrary if Bookshop fails
                  if (bookshopCoverUrl != null &&
                      bookshopCoverUrl.isNotEmpty &&
                      coverId != null &&
                      coverId.isNotEmpty) {
                    return Image.network(
                      'https://covers.openlibrary.org/b/id/$coverId-L.jpg',
                      width: 356,
                      height: 522,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image,
                        size: 64, color: Colors.grey[600]),
                  );
                },
              )
            : Container(
                color: Colors.grey[300],
                child:
                    Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
              ),
      ),
    );
  }
}
