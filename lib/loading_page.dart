import 'package:bookswiperapp/authentication_page.dart';
import 'package:bookswiperapp/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoadingPage extends StatefulWidget {
  final Future<void> Function()? onLoaded;
  const LoadingPage({Key? key, this.onLoaded}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  final List<String> _headlines = [
    "Getting books",
    "Fetching narratives",
    "Unlocking stories",
    "Reaching romantics",
    "Charming comedies",
    "Exploring mysteries",
    "Discovering adventures",
    "Finding classics",
    "Curating favorites",
  ];
  int _headlineIndex = 0;
  Timer? _headlineTimer;

  @override
  void initState() {
    super.initState();
    _waitForBooks();
    _startHeadlineCycling();
  }

  void _startHeadlineCycling() {
    _headlineTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _headlineIndex = (_headlineIndex + 1) % _headlines.length;
      });
    });
  }

  @override
  void dispose() {
    _headlineTimer?.cancel();
    super.dispose();
  }

  Future<void> _waitForBooks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final booksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('books');
      await for (var snapshot in booksRef.snapshots()) {
        print("books in snapshot: ${snapshot.docs.length}");
        if (snapshot.docs.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isFetchingBooks': false});
          break;
        }
      }
    }
    if (widget.onLoaded != null) await widget.onLoaded!();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.colorScheme.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _headlines[_headlineIndex],
                style: appTheme.textTheme.headlineMedium!.copyWith(
                  color: appTheme.colorScheme.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This may take a moment as we search deep in the catalogues of OpenLibrary.org',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'lib/assets/openlib_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedDashedLine(width: 80, height: 2),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: RiveAnimation.asset(
                      'lib/assets/loading_book.riv',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Logout'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated dashed line widget
class AnimatedDashedLine extends StatefulWidget {
  final double width;
  final double height;
  const AnimatedDashedLine(
      {Key? key, required this.width, required this.height})
      : super(key: key);

  @override
  State<AnimatedDashedLine> createState() => _AnimatedDashedLineState();
}

class _AnimatedDashedLineState extends State<AnimatedDashedLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: DashedLinePainter(offset: _controller.value),
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final double offset;
  DashedLinePainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height
      ..style = PaintingStyle.stroke;
    double startX = ((dashWidth + dashSpace) * offset);
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.offset != offset;
}
