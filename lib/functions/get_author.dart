import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Author {
  final Map<String, dynamic> data;

  Author({required this.data});

  factory Author.fromMap(Map<String, dynamic> map) {
    return Author(data: map);
  }

  String get name => data['name'] ?? data['author'] ?? '';
  String get bio => data['bio'] ?? '';
  String? get birthDate => data['birth_date'];
  String? get deathDate => data['death_date'];
  List<String> get alternateNames =>
      List<String>.from(data['alternate_names'] ?? []);
  List<dynamic> get photos => data['photos'] ?? [];
  List<dynamic> get links => data['links'] ?? [];
  Map<String, dynamic> get remoteIds =>
      Map<String, dynamic>.from(data['remote_ids'] ?? {});

  // ISBNdb specific fields
  String? get image => data['image'];
  List<dynamic> get books {
    final rawBooks = data['books'] ?? [];
    if (rawBooks is List) {
      final seenTitles = <String>{};
      return rawBooks.where((book) {
        final title = (book is Map && book['title'] != null)
            ? book['title'].toString()
            : '';
        if (title.isEmpty || seenTitles.contains(title)) {
          return false;
        }
        seenTitles.add(title);
        return true;
      }).toList();
    }
    return [];
  }

  String? get website => data['website'];
  String? get biography => data['biography'];

  // Helper methods
  String? get photoUrl {
    if (photos.isNotEmpty) {
      return 'https://covers.openlibrary.org/a/id/${photos[0]}-L.jpg';
    }
    return image; // Fallback to ISBNdb image if available
  }

  String get displayBio {
    if (biography != null && biography!.isNotEmpty) {
      return biography!;
    }
    final bioData = data['bio'];
    if (bioData != null) {
      if (bioData is Map<String, dynamic>) {
        return bioData['value']?.toString() ?? '';
      }
      return bioData.toString();
    }
    return 'No biography available';
  }
}

// Helper function to search OpenLibrary for author biographical info
Future<Map<String, dynamic>?> _searchOpenLibraryAuthor(
    String authorName) async {
  try {
    // Search for the author by name
    final searchUrl =
        'https://openlibrary.org/search/authors.json?q=${Uri.encodeComponent(authorName)}';
    final searchResponse = await http.get(Uri.parse(searchUrl));

    if (searchResponse.statusCode == 200) {
      final searchData = json.decode(searchResponse.body);
      final docs = searchData['docs'] as List?;

      if (docs != null && docs.isNotEmpty) {
        // Get the first match and fetch detailed info
        final authorKey = docs[0]['key'];
        if (authorKey != null) {
          // Ensure proper URL formatting - authorKey should start with /authors/
          final detailUrl = 'https://openlibrary.org/authors/$authorKey.json';
          final detailResponse = await http.get(Uri.parse(detailUrl));
          if (detailResponse.statusCode == 200) {
            return json.decode(detailResponse.body);
          }
        }
      }
    }
    return null;
  } catch (e) {
    print('Error fetching OpenLibrary author data: $e');
    return null;
  }
}

Future<Author?> getAuthorInfo(String authorName) async {
  try {
    // First, get ISBNdb data via Cloud Function
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('fetchAuthorInfo');

    final result = await callable.call({
      'authorName': authorName,
    });
    Map<String, dynamic> combinedData = {};

    // Extract ISBNdb data
    if (result.data != null) {
      final authorData = result.data as Map<String, dynamic>;
      // Handle the response structure from your Cloud Function
      if (authorData['details'] != null) {
        combinedData = Map<String, dynamic>.from(authorData['details']);
      } else {
        combinedData = Map<String, dynamic>.from(authorData);
      }
    }

    // Try to enrich with OpenLibrary biographical data
    try {
      final openLibraryData = await _searchOpenLibraryAuthor(authorName);
      if (openLibraryData != null) {
        // Merge OpenLibrary data, giving priority to biographical info
        if (openLibraryData['bio'] != null) {
          combinedData['bio'] = openLibraryData['bio'];
        }
        if (openLibraryData['birth_date'] != null) {
          combinedData['birth_date'] = openLibraryData['birth_date'];
        }
        if (openLibraryData['death_date'] != null) {
          combinedData['death_date'] = openLibraryData['death_date'];
        }
        if (openLibraryData['alternate_names'] != null) {
          combinedData['alternate_names'] = openLibraryData['alternate_names'];
        }
        if (openLibraryData['photos'] != null) {
          combinedData['photos'] = openLibraryData['photos'];
        }
        if (openLibraryData['links'] != null) {
          combinedData['links'] = openLibraryData['links'];
        }
        if (openLibraryData['remote_ids'] != null) {
          combinedData['remote_ids'] = openLibraryData['remote_ids'];
        }
        // Ensure we have the author name
        if (combinedData['name'] == null && openLibraryData['name'] != null) {
          combinedData['name'] = openLibraryData['name'];
        }
      }
    } catch (e) {
      print('Failed to fetch OpenLibrary data, using ISBNdb only: $e');
    }

    // If we have any data, create the Author object
    if (combinedData.isNotEmpty) {
      // Ensure we at least have the author name
      if (combinedData['name'] == null && combinedData['author'] == null) {
        combinedData['name'] = authorName;
      }
      return Author.fromMap(combinedData);
    }

    return null;
  } catch (e) {
    print('Error fetching author info: $e');
    return null;
  }
}
