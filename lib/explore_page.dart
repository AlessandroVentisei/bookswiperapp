import 'package:bookswiperapp/home.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:math';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePage createState() => _ExplorePage();
}

class _ExplorePage extends State<ExplorePage> {
  int cardIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Container> cards = [
      Container(
        height: 400, // Fixed height for the card
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: appTheme.colorScheme.primary),
        child: SingleChildScrollView(
          controller: _scrollController,
          clipBehavior: Clip.none,
          child: Column(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  double scale =
                      1 - (_scrollController.offset / 1000).clamp(0, 0.5);
                  double height = 550 *
                      pow(scale, 2).toDouble(); // Adjust the height dynamically
                  return Container(
                    height: height,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    'https://picsum.photos/200/300',
                    width: double.infinity,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                spacing: 12,
                children: [
                  Text("1984", style: appTheme.textTheme.headlineMedium),
                  Text("George Orwell",
                      style: appTheme.textTheme.headlineSmall),
                ],
              ),
              Text(
                  "Nineteen Eighty-Four, often referred to as 1984, is a dystopian social science fiction novel by the English novelist George Orwell.",
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
      Container(
        height: 400, // Fixed height for the card
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: appTheme.colorScheme.primary),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Column(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  // Adjust the height dynamically
                  return Container(
                    height: 500,
                    child: Transform.scale(
                      scale: 1,
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    'https://picsum.photos/200/300',
                    width: double.infinity,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                spacing: 12,
                children: [
                  Text("1984", style: appTheme.textTheme.headlineMedium),
                  Text("George Orwell",
                      style: appTheme.textTheme.headlineSmall),
                ],
              ),
              Text(
                  "Nineteen Eighty-Four, often referred to as 1984, is a dystopian social science fiction novel by the English novelist George Orwell.",
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
              Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  style: appTheme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 10,
        elevation: 0,
        shadowColor: Colors.black45,
        title: Text(
          'Explore Books',
          style: appTheme.textTheme.headlineMedium,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          },
        ),
      ),
      backgroundColor: appTheme.colorScheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: CardSwiper(
              cardsCount: cards.length,
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                return cards[index];
              },
            ),
          );
        },
      ),
    );
  }
}
