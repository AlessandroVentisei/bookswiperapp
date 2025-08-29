import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/get_books.dart';

/// Fetches the next batch of books for the current user and adds them to the user's Firestore index list.
/// Returns a list of Book objects.
Future<List<Book>> fetchBooks({
  required int batchSize,
  DocumentSnapshot? lastDoc,
}) async {
  final user = FirebaseAuth.instance.currentUser!;
  final userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('books')
      .orderBy('index', descending: false);
  Query query = userRef.limit(batchSize);
  if (lastDoc != null) {
    query = query.startAfterDocument(lastDoc);
  }
  final snapshot = await query.get();
  final books = snapshot.docs
      .map((doc) =>
          Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
  // return the number of books to reload the user's queueing system.
  return books;
}
