import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

setupNewUser(User user) async {
  // Check if the user is new and create a document in Firestore if not exists
  // Check if the user is signed in
  // If the user is not signed in, return
  var db = FirebaseFirestore.instance;
  if (user != null) {
    final userId = user.uid;
    final userRef = db.collection('users').doc(userId);
    userRef.get().then((doc) {
      // if no user document exists, create one.
      if (!doc.exists) {
        // User does not exist, create a new document
        userRef.set({
          'uid': userId,
          'email': user.email,
          'displayName': user.displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isNewUser': true,
        });
      }
    });
  }
}
