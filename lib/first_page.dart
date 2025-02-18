import 'package:bookswiperapp/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class FirstOpen extends StatelessWidget {
  List<Container> cards = [
    Container(
      height: 600,
      width: 357,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('1', style: appTheme.textTheme.headlineMedium),
          Text('This is the first card', style: appTheme.textTheme.bodyLarge),
        ],
      ),
    ),
    Container(
      height: 600,
      width: 357,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('2', style: appTheme.textTheme.headlineMedium),
          Text('This is the second card', style: appTheme.textTheme.bodyLarge),
        ],
      ),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      appBar: AppBar(
        title: Text('First Page'),
      ),
      body: Center(
        child: CardSwiper(
          allowedSwipeDirection: AllowedSwipeDirection.only(left: true),
          cardsCount: 2,
          cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
              cards[index],
        ),
      ),
    );
  }
}
