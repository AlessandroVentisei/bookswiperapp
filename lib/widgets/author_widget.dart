import 'package:flutter/material.dart';
import 'package:bookswiperapp/theme/theme.dart';

class AuthorWidget extends StatelessWidget {
  final String authorName;

  const AuthorWidget({
    Key? key,
    required this.authorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/authorDetails',
            arguments: {'authorName': authorName},
          );
        },
        child: Text(
          authorName,
          style: appTheme.textTheme.bodyLarge,
        ));
  }
}
