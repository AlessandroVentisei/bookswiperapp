import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Define the Book data type
class Book {
  final Map<String, dynamic> data;
  final String docId;

  Book({required this.data, required this.docId});

  factory Book.fromFirestore(Map<String, dynamic> data, String docId) {
    return Book(data: data, docId: docId);
  }

  // Create a Book from a Map (e.g., from JSON or Firestore)
  factory Book.fromMap(Map<String, dynamic> map, {required String docId}) {
    return Book(data: map, docId: docId);
  }

  Map<String, dynamic> toFirestore() => data;

  String get title => data['title'] ?? '';

  // Updated for ISBNdb format - authors is now a simple string array
  List<String> get authors {
    final authorsData = data['authors'];
    if (authorsData is List) {
      return authorsData
          .map((author) => author.toString())
          .where((name) => name.isNotEmpty)
          .toList();
    }
    return ['Unknown Author'];
  }

  // Legacy getter for backward compatibility
  List<Map<String, dynamic>> get authorsLegacy {
    // Convert new format to old format for backward compatibility
    final authorStrings = authors;
    return authorStrings
        .map((name) => {
              'name': name,
              'details': {'name': name}
            })
        .toList();
  }

  // Updated field mappings for ISBNdb
  List<String> get subjects => List<String>.from(data['subjects'] ?? []);

  String get isbn => data['isbn'] ?? data['isbn10'] ?? '';
  String get isbn_13 => data['isbn13'] ?? '';

  // ISBNdb uses 'image' instead of cover IDs
  String get coverImageUrl {
    final imageUrl = data['image'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }
    // Fallback to original image if available
    final originalUrl = data['image_original'];
    if (originalUrl != null && originalUrl.isNotEmpty) {
      return originalUrl;
    }
    return '';
  }

  // Legacy cover property - return 0 since ISBNdb doesn't use cover IDs
  int get cover => 0;

  // New ISBNdb specific properties
  String get publisher => data['publisher'] ?? '';
  int get pages => data['pages'] ?? 0;
  String get datePublished => data['date_published'] ?? '';
  int? get firstPublishYear {
    final date = data['date_published'];
    if (date != null) {
      return int.tryParse(date.toString());
    }
    return null;
  }

  String get language => data['language'] ?? '';
  String get binding => data['binding'] ?? '';

  // Legacy bookKey - use ISBN as identifier
  String get bookKey => isbn.isNotEmpty ? '/books/$isbn' : '';

  String get description {
    // ISBNdb typically doesn't have descriptions, but check if available
    if (data['description'] is String) {
      return data['description'];
    } else if (data['description'] is Map &&
        (data['description'] as Map)['value'] is String) {
      return (data['description'] as Map)['value'];
    }
    return 'No description available';
  }

  String? get bookshopCoverUrl => data['bookshop_cover_url'];
}

Future<List<Book>> getBooks(User user) async {
  var db = FirebaseFirestore.instance;
  final userId = user.uid;
  final userRef = db.collection('users').doc(userId).collection("books");
  try {
    final querySnapshot = await userRef.get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.map<Book>((doc) {
        final data = doc.data();
        return Book.fromFirestore(data, doc.id); // Pass doc.id to fromFirestore
      }).toList();
    } else {
      print('No books found in the user\'s collection.');
      return [];
    }
  } catch (e) {
    print('Error fetching books: $e');
    return [];
  }
}

uploadTrendingBooks(User user) async {
  var db = FirebaseFirestore.instance;
  final userId = user.uid;
  final userRef = db.collection('users').doc(userId);
  final trendingBooksCollection = userRef.collection('books');

  try {
    // Load the JSON file
    final String jsonString = await File(
            '/Users/Alex/Desktop/FlutterDev/bookswiperapp/lib/trending_works/trending_works.json')
        .readAsString();
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Extract specific keys and batch write them
    final List<dynamic> works = jsonData['works'] ?? [];
    WriteBatch batch = db.batch();
    for (var work in works) {
      if (work is Map<String, dynamic>) {
        final extractedData = {
          'title': work['title'] ?? '',
          'description': work['description'] != null &&
                  work['description'] is Map<String, dynamic>
              ? work['description']['value'] ?? ''
              : (work['description'] ?? ''),
          'authors': work['authors'] != null && work['authors'] is List
              ? work['authors']
                  .map((author) => author['author']['key']?.toString() ?? '')
                  .toList()
              : [],
          'key': work['key'] ?? '',
          'cover': work['covers'] != null && work['covers'] is List
              ? work['covers'][0]
              : 0,
          'subjects': work['subjects'] ?? [],
        };
        final docRef =
            trendingBooksCollection.doc(); // Create a new document reference
        batch.set(docRef, extractedData);
      }
    }

    // Commit the batch
    try {
      await batch.commit();
    } catch (e) {
      // Handle errors (e.g., log them)
      print('Batch commit failed: $e');
    }
  } catch (e) {
    // Handle errors (e.g., log them)
    print('Error loading JSON or processing data: $e');
  }
}
