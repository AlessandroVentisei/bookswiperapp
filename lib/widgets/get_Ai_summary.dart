import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bookswiperapp/theme/theme.dart';

/// Convenience wrapper that returns a ready-to-use button widget.
/// Usage:
///   aiSummaryButton(
///     bookDocId: book.docId,
///     bookKey: book.data['key'],
///     title: book.title,
///     author: book.authorNames.isNotEmpty ? book.authorNames.first : '',
///   )
Widget aiSummaryButton({
  required String bookDocId,
  required String bookKey,
  required String title,
  required String author,
  String label = 'Get AI Summary',
}) =>
    _AiSummaryButton(
      bookDocId: bookDocId,
      bookKey: bookKey,
      title: title,
      author: author,
      label: label,
    );

class _AiSummaryButton extends StatefulWidget {
  final String bookDocId;
  final String bookKey;
  final String title;
  final String author;
  final String label;

  const _AiSummaryButton({
    required this.bookDocId,
    required this.bookKey,
    required this.title,
    required this.author,
    required this.label,
  });

  @override
  State<_AiSummaryButton> createState() => _AiSummaryButtonState();
}

class _AiSummaryButtonState extends State<_AiSummaryButton> {
  bool _loading = false;
  double _progress = 0.0;
  Timer? _progressTimer;
  bool _fetched = false;
  int _usage = 0;
  int allowance = 10;

  @override
  void initState() {
    super.initState();
    _checkIfFetched();
  }

  Future<void> _checkIfFetched() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      // Load user-level usage and subscription
      final userSnap = await userDoc.get();
      final Map<String, dynamic>? userData = userSnap.data();
      bool isSubscribed = false;
      int usageCount = 0;
      if (userData != null) {
        final dynamic cnt = userData['aiSummariesCount'];
        if (cnt is int) usageCount = cnt;
        isSubscribed = userData['isSubscribed'] == true ||
            userData['subscriptionActive'] == true ||
            userData['pro'] == true; // fallback flags if present
      }
      final bookDocRef = userDoc.collection('books').doc(widget.bookDocId);
      final snap = await bookDocRef.get();
      final data = snap.data();
      final fetched = (data?['ai_summary_fetched'] == true) ||
          (data?['ai_summary'] != null);
      if (!mounted) return;
      setState(() {
        _fetched = fetched;
        _usage = usageCount;
        allowance = isSubscribed ? 100 : 10;
      });
    } catch (_) {}
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    const totalMs = 10000; // 10 seconds
    const tickMs = 100; // update every 100ms
    final steps = totalMs / tickMs; // 100 steps
    final increment = 0.9 / steps; // reach ~90% in 10s
    _progressTimer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + increment).clamp(0.0, 0.9);
      });
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _completeProgress() {
    if (!mounted) return;
    setState(() => _progress = 1.0);
    _stopProgressTimer();
  }

  Future<void> _handlePress() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _progress = 0.0;
    });
    _startProgressTimer();

    final user = FirebaseAuth.instance.currentUser;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final bookDocRef = userDoc.collection('books').doc(widget.bookDocId);
    bool prevFetched = false;
    try {
      final beforeSnap = await bookDocRef.get();
      prevFetched = (beforeSnap.data()?['ai_summary_fetched'] == true);
    } catch (_) {}

    Map<String, dynamic>? summary;
    List<dynamic> sources = const [];

    try {
      // Call the callable function if it has not already been done
      if (!prevFetched && _usage < allowance) {
        final callable =
            FirebaseFunctions.instance.httpsCallable('fetchAiSummary');
        await callable.call({
          'user': user.uid,
          'key': widget.bookKey,
          'title': widget.title,
          'author': widget.author,
        });
      } else if (_usage >= allowance) {
        // Show a message indicating the user has reached their limit
        _showSnack('You have reached your usage limit.', false);
        throw Exception('resource-exhausted');
      }

      // After success, fetch the updated book doc for summary and sources
      final snap = await bookDocRef.get();
      final data = snap.data();
      if (data != null) {
        final rawSummary = data['ai_summary'];
        if (rawSummary is Map<String, dynamic>) {
          summary = rawSummary;
        } else if (rawSummary is String) {
          summary = {'text': rawSummary};
        }
        final sro = data['search_result_organic'];
        if (sro is List) sources = sro;
      }

      // Increment counter only if this is newly fetched
      final nowFetched = (summary != null);
      if (!prevFetched && nowFetched) {
        await userDoc.update({'aiSummariesCount': FieldValue.increment(1)});
      }
      if (nowFetched && mounted) setState(() => _fetched = true);
      if (!prevFetched && nowFetched && mounted) {
        setState(() {
          _usage = (_usage + 1);
        });
      }

      if (!mounted) return;
      if (summary == null) {
        _showSnack('No summary available yet. Please try again.', false);
      } else {
        _showSummarySheet(summary, sources);
      }
    } on FirebaseFunctionsException catch (e) {
      // If already fetched, just read and show
      if (e.code == 'failed-precondition') {
        try {
          final snap = await bookDocRef.get();
          final data = snap.data();
          if (data != null) {
            final rawSummary = data['ai_summary'];
            if (rawSummary is Map<String, dynamic>) {
              summary = rawSummary;
            } else if (rawSummary is String) {
              summary = {'text': rawSummary};
            }
            final sro = data['search_result_organic'];
            if (sro is List) sources = sro;
          }
          if (!mounted) return;
          if (summary != null) {
            _showSummarySheet(summary, sources);
            if (mounted) setState(() => _fetched = true);
          } else {
            _showSnack('Summary already fetched, but not found.', false);
          }
        } catch (err) {
          _showRetrySnack('Couldn\'t load saved summary.');
        }
      } else if (e.code == 'not-found') {
        _showRetrySnack('Book not found.');
      } else if (e.code == 'resource-exhausted') {
        _showSnack('You have reached your usage limit for this week.', false);
      } else {
        final msg = e.message ?? 'Something went wrong.';
        _showRetrySnack('Error: ' + msg);
      }
    } catch (e) {
      _showRetrySnack('Error fetching summary.');
    } finally {
      _completeProgress();
      if (mounted) {
        setState(() => _loading = false);
        // reset for next use
        _progress = 0.0;
      }
    }
  }

  void _showSnack(String msg, bool showPlus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Wrap(
        children: [
          Text(msg),
          showPlus
              ? TextButton(
                  onPressed: () => _showAllowanceInfo(),
                  child: Text("More summaries?"))
              : Container()
        ],
      )),
    );
  }

  void _showRetrySnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Try again',
          onPressed: _handlePress,
        ),
      ),
    );
  }

  void _showAllowanceInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bool isPlus = allowance >= 100;
        final bool isFree = !isPlus;
        final borderColor = appTheme.colorScheme.secondary;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.6,
          builder: (_, controller) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 12,
                children: [
                  Text("Curious??",
                      style: appTheme.textTheme.headlineMedium!
                          .copyWith(color: appTheme.colorScheme.onSecondary)),
                  Text(
                      "AI summaries let you get more insight than ever into books you've never seen before.",
                      style: appTheme.textTheme.bodyMedium!
                          .copyWith(color: appTheme.colorScheme.onSecondary)),
                  // container indicating free subscription
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: appTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: isFree
                          ? Border.all(color: borderColor, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          "Free: 10 summaries/week.",
                          textAlign: TextAlign.left,
                          style: appTheme.textTheme.headlineSmall!.copyWith(
                              color: appTheme.colorScheme.onSecondary),
                        ),
                        Text(
                          "A great way to get a taste of books you've never seen before at no cost.",
                          style: appTheme.textTheme.bodySmall!.copyWith(
                              color: appTheme.colorScheme.onSecondary),
                        )
                      ],
                    ),
                  ),
                  // container indicating plus subscription
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: appTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: isPlus
                          ? Border.all(color: borderColor, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Wrap(
                          spacing: 12,
                          children: [
                            Text(
                              "Plus: 100 summaries/week",
                              style: appTheme.textTheme.headlineSmall!.copyWith(
                                  color: appTheme.colorScheme.onSecondary),
                            ),
                            Text(
                              "£2.99/month",
                              style: appTheme.textTheme.bodySmall!.copyWith(
                                  color: appTheme.colorScheme.onSecondary),
                            ),
                          ],
                        ),
                        Text(
                          "Get insights into all the books you can handle and support the app's development.",
                          style: appTheme.textTheme.bodySmall!.copyWith(
                              color: appTheme.colorScheme.onSecondary),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => {},
                      child: const Text('Upgrade (coming soon)',
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                ],
              )),
        );
      },
    );
  }

  void _showSummarySheet(Map<String, dynamic> summary, List<dynamic> sources) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.colorScheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final sections = _extractSections(summary);
        final topSources = sources.take(2).toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              controller: controller,
              children: [
                Text('Summary', style: appTheme.textTheme.headlineMedium),
                Row(
                  spacing: 4,
                  children: [
                    Text(
                      "Used ${_usage} of ${allowance} AI research summaries.",
                      style: appTheme.textTheme.bodyMedium!.copyWith(
                          color: appTheme.colorScheme.onPrimary.withAlpha(150)),
                    ),
                    IconButton(
                      iconSize: 16,
                      icon: Icon(
                        Icons.info_outline,
                        color: appTheme.colorScheme.onPrimary.withAlpha(200),
                      ),
                      onPressed: _showAllowanceInfo,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sections,
                const SizedBox(height: 16),
                if (topSources.isNotEmpty) ...[
                  Text('Top sources', style: appTheme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  ...topSources.map((s) => _buildSourceTile(s)).toList(),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _extractSections(Map<String, dynamic> summary) {
    // If summary is plain text
    if (summary.containsKey('text') && summary['text'] is String) {
      return [
        Text(
          summary['text'],
          style: appTheme.textTheme.bodyMedium,
        )
      ];
    }

    // Otherwise, render known sections in a friendly order
    final order = <String>[
      'Overview',
      'Setting',
      'Key themes',
      'Characters',
      'Conclusion'
    ];
    final List<Widget> out = [];
    for (final key in order) {
      final val = summary[key];
      if (val is String && val.trim().isNotEmpty) {
        out.addAll([
          Text(key, style: appTheme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(val, style: appTheme.textTheme.bodyMedium),
          const SizedBox(height: 12),
        ]);
      }
    }

    // Add any remaining string fields not in the known order
    summary.forEach((k, v) {
      if (!order.contains(k) && v is String && v.trim().isNotEmpty) {
        out.addAll([
          Text(k, style: appTheme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(v, style: appTheme.textTheme.bodyMedium),
          const SizedBox(height: 12),
        ]);
      }
    });
    if (out.isEmpty) {
      out.add(
          Text('No summary available.', style: appTheme.textTheme.bodyMedium));
    }
    return out;
  }

  Widget _buildSourceTile(dynamic s) {
    String title = '';
    String url = '';
    if (s is Map) {
      title = (s['title'] ?? s['name'] ?? s['displayed_link'] ?? '').toString();
      url = (s['link'] ?? s['url'] ?? '').toString();
    } else {
      title = s.toString();
    }
    if (title.isEmpty) title = 'Source';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: appTheme.textTheme.bodyLarge),
      subtitle: url.isNotEmpty
          ? Text(url, style: appTheme.textTheme.bodySmall)
          : null,
      trailing: url.isNotEmpty ? const Icon(Icons.open_in_new, size: 18) : null,
      onTap: url.isNotEmpty && _isValidUrl(url)
          ? () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
          : null,
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: appTheme.colorScheme.secondary,
        foregroundColor: appTheme.colorScheme.onSecondary,
        minimumSize: const Size(140, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: _loading
          ? SizedBox(
              width: 120,
              height: 4,
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                      appTheme.colorScheme.onSecondary.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    appTheme.colorScheme.onSecondary,
                  ),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              spacing: 6,
              children: [
                Icon(Icons.generating_tokens, size: 16),
                Text(_fetched ? "View summary" : "Get summary"),
              ],
            ),
    );
  }
}
