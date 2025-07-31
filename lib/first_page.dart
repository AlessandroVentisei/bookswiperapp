import 'package:bookswiperapp/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'authentication_page.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class FirstOpen extends StatefulWidget {
  final Future<void> Function()? onFinished;
  const FirstOpen({super.key, this.onFinished});

  @override
  _FirstOpenState createState() => _FirstOpenState();
}

class _FirstOpenState extends State<FirstOpen> {
  int cardIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<Container> cards = [
      Container(
        height: 600,
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: [0, 1.0],
            colors: [Color(0xFF252525), Color(0xFF1E1E1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                constraints: BoxConstraints.expand(width: 60, height: 60),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.fromARGB(65, 140, 140, 140),
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: EdgeInsets.all(12),
                child: Text(
                  '👍',
                  style: TextStyle(fontSize: 24),
                )),
            Text('Swipe Right', style: appTheme.textTheme.headlineMedium),
            Text(
                'If you like the look of a book, simply swipe right to like it.',
                style: appTheme.textTheme.bodyLarge),
          ],
        ),
      ),
      Container(
        height: 600,
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: [0, 1.0],
            colors: [Color(0xFF252525), Color(0xFF1E1E1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                constraints: BoxConstraints.expand(width: 60, height: 60),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.fromARGB(65, 140, 140, 140),
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: EdgeInsets.all(12),
                child: Text(
                  '👎',
                  style: TextStyle(fontSize: 24),
                )),
            Text('Swipe Left', style: appTheme.textTheme.headlineMedium),
            Text(
                "If you don't like the look of a book, simply swipe left to dislike it.",
                style: appTheme.textTheme.bodyLarge),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/auth");
            },
            child: Text(
              'Skip',
              style: TextStyle(color: appTheme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      body: CardSwiper(
        isLoop: false,
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          if (index < 0 || index >= cards.length) {
            Navigator.pushReplacementNamed(context, "/auth");
            return Container(); // Return an empty container for out-of-bounds indices
          }
          // Ensure index is within bounds
          return cards[index];
        },
        onSwipe: (previousIndex, currentIndex, direction) {
          previousIndex == 1
              ? Navigator.pushReplacementNamed(context, "/auth")
              : print(currentIndex);
          setState(() {
            cardIndex = currentIndex!.toInt();
          });
          return true;
        },
        allowedSwipeDirection: AllowedSwipeDirection.only(
            left: cardIndex == 1 ? true : false,
            right: cardIndex == 0 ? true : false),
        cardsCount: 2,
      ),
    );
  }
}
