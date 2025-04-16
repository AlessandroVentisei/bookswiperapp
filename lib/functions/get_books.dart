import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// Define the Book data type
class Book {
  final List<String> subjects;
  final List<String> subjectPeople;
  final List<String> subjectPlaces;
  final List<String> subjectTimes;
  final List<String> authors;
  final List<String> authorKey;
  final String title;
  final String bookKey;
  final int coverI;
  final String description;
  final String docId; // Add docId property

  Book({
    required this.subjects,
    required this.subjectPeople,
    required this.subjectPlaces,
    required this.subjectTimes,
    required this.authors,
    required this.authorKey,
    required this.title,
    required this.bookKey,
    required this.coverI,
    required this.description,
    required this.docId, // Add docId to constructor
  });

  // Factory method to create a Book from Firestore data
  factory Book.fromFirestore(Map<String, dynamic> data, String docId) {
    print(data); // Debugging: Print the Firestore data
    return Book(
      subjects: List<String>.from(data['subjects'] ?? []),
      subjectPeople: List<String>.from(data['subject_people'] ?? []),
      subjectPlaces: List<String>.from(data['subject_places'] ?? []),
      subjectTimes: List<String>.from(data['subject_times'] ?? []),
      authors: data['authors'] is List
          ? List<String>.from(data['authors'].map((e) => e.toString()))
          : [data['authors']?.toString() ?? ''],
      authorKey: data['author_key'] is List
          ? List<String>.from(data['author_key'].map((e) => e.toString()))
          : [data['author_key']?.toString() ?? ''],
      title: data['title'] ?? '',
      bookKey: data['workKey'] ?? '',
      coverI: data['coverId'] ?? 0,
      description: data['description'] ?? "",
      docId: docId, // Assign docId
    );
  }

  // Convert a Book to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'subjects': subjects,
      'subject_people': subjectPeople,
      'subject_places': subjectPlaces,
      'subject_times': subjectTimes,
      'authors': authors,
      'author_key': authorKey,
      'title': title,
      'book_key': bookKey,
      'cover_i': coverI,
      'description': description,
    };
  }
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
          'title': work['title'],
          'description': work['description'] != null &&
                  work['description'] is Map<String, dynamic>
              ? work['description']["value"] ?? ''
              : '',
          'author_name': work['author_name'],
          'key': work['key'],
          'cover_i': work['cover_i'],
          'first_publish_year': work['first_publish_year'],
          'subjects': work['subjects'] ?? [],
          'subject_people': work['subject_people'] ?? [],
          'subject_places': work['subject_places'] ?? [],
          'subject_times': work['subject_times'] ?? [],
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
