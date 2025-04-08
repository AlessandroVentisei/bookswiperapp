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
  final String authorName;
  final String authorKey;
  final String title;
  final String bookKey;
  final int coverI;

  Book({
    required this.subjects,
    required this.subjectPeople,
    required this.subjectPlaces,
    required this.subjectTimes,
    required this.authorName,
    required this.authorKey,
    required this.title,
    required this.bookKey,
    required this.coverI,
  });

  // Factory method to create a Book from Firestore data
  factory Book.fromFirestore(Map<String, dynamic> data) {
    return Book(
      subjects: List<String>.from(data['subjects'] ?? []),
      subjectPeople: List<String>.from(data['subject_people'] ?? []),
      subjectPlaces: List<String>.from(data['subject_places'] ?? []),
      subjectTimes: List<String>.from(data['subject_times'] ?? []),
      authorName: data['author_name'] is List
          ? (data['author_name'] as List).first.toString()
          : data['author_name'] ?? '',
      authorKey: data['author_key'] ?? '',
      title: data['title'] ?? '',
      bookKey: data['book_key'] ?? '',
      coverI: data['cover_i'] ?? 0,
    );
  }

  // Convert a Book to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'subjects': subjects,
      'subject_people': subjectPeople,
      'subject_places': subjectPlaces,
      'subject_times': subjectTimes,
      'author_name': authorName,
      'author_key': authorKey,
      'title': title,
      'book_key': bookKey,
      'cover_i': coverI,
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
        return Book.fromFirestore(data);
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
          'author_name': work['author_name'],
          'key': work['key'],
          'cover_i': work['cover_i'],
          'first_publish_year': work['first_publish_year'],
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
