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

  Map<String, dynamic> toFirestore() => data;

  String get title => data['title'] ?? '';
  String get isbn_13 => data['isbn_13'] ?? '';

  List<String> get subjects =>
      List<String>.from(data['subject'] ?? data['subjects'] ?? []);
  List<Map<String, dynamic>> get authors {
    if (data['authors'] is List) {
      return List<Map<String, dynamic>>.from((data['authors']));
    }
    return [];
  }

  int get cover {
    if (data['cover_id'] != null) return data['cover_id'];
    if (data['covers'] is List && data['covers'].isNotEmpty) {
      return data['covers'][0];
    }
    return 0;
  }

  String get bookKey => data['key'] ?? '';

  String get description {
    if (data['description'] is String) {
      return data['description'];
    } else if (data['description'] is Map &&
        (data['description'] as Map)['value'] is String) {
      return (data['description'] as Map)['value'];
    }
    return '';
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
