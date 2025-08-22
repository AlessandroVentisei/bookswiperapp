import 'package:bookswiperapp/theme/theme.dart';
import 'package:bookswiperapp/widgets/bookshop_link_button.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:rive/rive.dart';

class AuthorDetailsPage extends StatefulWidget {
  final String authorName;
  final String? reason; // Optional reason for the author details page
  final String? topWork; // Optional top work to highlight
  final String? avatarUrl; // Optional avatar URL
  final String? openLibraryUrl; // Optional Open Library URL

  const AuthorDetailsPage({
    super.key,
    required this.authorName,
    this.reason,
    this.topWork,
    this.avatarUrl,
    this.openLibraryUrl,
  });

  @override
  State<AuthorDetailsPage> createState() => _AuthorDetailsPageState();
}

class _AuthorDetailsPageState extends State<AuthorDetailsPage> {
  Map<String, dynamic>? authorData;
  bool isLoading = true;
  String? error;

  List<dynamic>? works;
  bool isLoadingWorks = true;

  @override
  void initState() {
    super.initState();
    fetchAuthorDetails();
    fetchAuthorWorks();
  }

  Future<void> fetchAuthorDetails() async {
    print(widget.reason);
    final url = 'https://openlibrary.org/authors/${widget.authorName}.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          authorData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load author details.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchAuthorWorks() async {
    final worksUrl =
        'https://openlibrary.org/authors/${widget.authorName}/works.json?limit=10';
    try {
      final response = await http.get(Uri.parse(worksUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          works = data['entries'];
          isLoadingWorks = false;
        });
      } else {
        setState(() {
          isLoadingWorks = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingWorks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.authorName,
          style: appTheme.textTheme.headlineMedium,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: RiveAnimation.asset(
                      '/Users/Alex/Desktop/FlutterDev/bookswiperapp/lib/assets/loading_book.riv',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      animations: const ['loading'],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Loading author details...",
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : error != null
              ? Center(child: Text(error!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (authorData?['photos'] != null &&
                                authorData!['photos'].isNotEmpty)
                            ? Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 16,
                                        spreadRadius: 4,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      'https://covers.openlibrary.org/b/id/${authorData!['photos'][0]}-L.jpg',
                                      height: 180,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.person,
                                  size: 180,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                        SizedBox(height: 16),
                        Text(
                          authorData?['name'] ?? widget.authorName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (authorData?['alternate_names'] != null &&
                            (authorData!['alternate_names'] as List).isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 4.0, bottom: 8.0),
                            child: Text(
                              'Also known as: ' +
                                  (authorData!['alternate_names'] as List)
                                      .take(3)
                                      .join(', '),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        SizedBox(height: 8),
                        if (widget.reason != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Text(
                              widget.reason!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        if (authorData?['bio'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Biography",
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              SizedBox(height: 8),
                              Text(
                                authorData!['bio'] is String
                                    ? authorData!['bio']
                                    : authorData!['bio']['value'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        if (authorData?['title'] != null) SizedBox(height: 16),
                        if (authorData?['birth_date'] != null)
                          Text('Born: ${authorData!['birth_date']}'),
                        if (authorData?['death_date'] != null)
                          Text('Died: ${authorData!['death_date']}'),
                        if (authorData?['links'] != null &&
                            (authorData!['links'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8,
                              children: (authorData!['links'] as List)
                                  .take(3)
                                  .map<Widget>((link) => InkWell(
                                        onTap: () =>
                                            launchUrl(Uri.parse(link['url'])),
                                        child: Text(
                                          link['title'] ?? link['url'],
                                          style: TextStyle(
                                            color:
                                                appTheme.colorScheme.onPrimary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                appTheme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        if (widget.topWork != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                              ),
                              Text(
                                "Top Work",
                                style: appTheme.textTheme.headlineSmall,
                              ),
                              ListTile(
                                leading: BookshopLinkButton(
                                  title: widget.topWork,
                                  format: "small",
                                ),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  widget.topWork.toString(),
                                  style: appTheme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                onTap: () {
                                  launchUrl(Uri.parse(
                                      'https://uk.bookshop.org/search?affiliate=15242&keywords=${("${widget.topWork} ${widget.authorName}").replaceAll(' ', '+')}'));
                                },
                              )
                            ],
                          ),
                        SizedBox(height: 24),
                        Text('Notable Works:',
                            style: appTheme.textTheme.headlineSmall),
                        if (isLoadingWorks)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (works != null && works!.isNotEmpty)
                          ...works!.take(5).map((work) => ListTile(
                                leading: BookshopLinkButton(
                                  title: work['title'],
                                  format: "small",
                                ),
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  work['title'] ?? 'Untitled',
                                  style: appTheme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                subtitle: work['description'] != null
                                    ? Text(
                                        work['description'] is String
                                            ? work['description']
                                            : work['description']['value'] ??
                                                '',
                                        style: appTheme.textTheme.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onTap: () {
                                  final workKey = work['key'];
                                  if (workKey != null) {
                                    launchUrl(Uri.parse(
                                        'https://uk.bookshop.org/search?affiliate=15242&keywords=${work["title"]?.replaceAll(' ', '+') ?? ''}'));
                                  }
                                },
                              )),
                        if (works != null && works!.isEmpty)
                          Text(
                            'No works found.',
                            style: appTheme.textTheme.bodyLarge,
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
