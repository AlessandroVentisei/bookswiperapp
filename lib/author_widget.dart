import 'package:flutter/material.dart';
import 'package:bookswiperapp/theme/theme.dart';

class AuthorWidget extends StatelessWidget {
  final String authorName;
  final String authorKey;

  const AuthorWidget({
    Key? key,
    required this.authorName,
    required this.authorKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/authorDetails',
            arguments: {'authorKey': authorKey, 'authorName': authorName},
          );
        },
        child: Text(
          authorName,
          style: appTheme.textTheme.bodyLarge,
        ));
  }
}
