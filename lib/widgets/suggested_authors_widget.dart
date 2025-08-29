import 'package:bookswiperapp/author_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bookswiperapp/theme/theme.dart';

class SuggestedAuthorsWidget extends StatelessWidget {
  const SuggestedAuthorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggested Authors",
          style: appTheme.textTheme.displayMedium,
        ),
        Container(
          height: 140,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("Error loading authors.");
              }
              if (snapshot.hasData &&
                  snapshot.data!.exists &&
                  snapshot.data!.data() != null) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final authors =
                    userData['shortlistedAuthors'] as List<dynamic>?;

                if (authors == null || authors.isEmpty) {
                  return Text("No suggested authors found.");
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: authors.length,
                  itemBuilder: (context, index) {
                    final author = authors[index] as Map<String, dynamic>;
                    final name = author['name'] ?? 'Unknown';
                    final reason = author['reason'] ?? '';
                    final topWork = author['top_work'] ?? '';
                    final workCount = author['work_count']?.toString() ?? '';
                    final key = author['key'];
                    final openLibraryUrl = key != null &&
                            key.toString().isNotEmpty
                        ? 'https://covers.openlibrary.org/a/olid/${key.toString().replaceAll('/authors/', '')}-M.jpg'
                        : null;
                    final avatarUrl =
                        'https://api.dicebear.com/9.x/micah/png?backgroundColor=d0d6b3&seed=${Uri.encodeComponent(name)}';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthorDetailsPage(
                            authorName: name,
                            authorKey: key,
                            reason: reason,
                            topWork: topWork,
                            avatarUrl: avatarUrl,
                            openLibraryUrl: openLibraryUrl,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 92,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.network(
                                    avatarUrl,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (openLibraryUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: Image.network(
                                      openLibraryUrl,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // If OpenLibrary image fails, show nothing (avatar remains)
                                        return SizedBox.shrink();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: appTheme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return Text("No suggested authors found.");
            },
          ),
        )
      ],
    );
  }
}
