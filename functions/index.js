/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios"); // Add axios for HTTP requests
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const functions = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

initializeApp(); // Initialize Firebase Admin SDK
const db = getFirestore(); // Get Firestore instance

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// I need functions for: when
// 1. A user signs up, create a queue for them
// 2. A use likes a book
// 3. A user dislikes a book
// 4. More books need to be fetched.
// 5. A user wants to see trending books

exports.likeBook = onCall(async (request, response) => {
    // This function will handle the liking of a book
    // it must remove the book from the queue and add it to the liked books
    // then it updates the users subject keywords
    const user = request.data.user; // Assuming user is passed in request
    const book = request.data.book; // Assuming book doc id is passed in request
    if (!user) {
        throw new HttpsError("invalid-argument", "Missing user param.");
    } else if (!book) {
        throw new HttpsError("invalid-argument", "Missing book param.");
    }
    // move book from queue to liked books
    const userQueueRef = db.collection("users").doc(user).collection("books");
    const likedBooksRef = db.collection("users").doc(user).collection("likedBooks");

    try {
        // Get the book document
        const bookDoc = await userQueueRef.doc(book).get();
        if (!bookDoc.exists) {
            throw new HttpsError("not-found", "Book not found in queue.");
        }

        const bookData = bookDoc.data();

        // Add the book to the likedBooks collection
        await likedBooksRef.doc(book).set(bookData);

        // Remove the book from the queue
        await userQueueRef.doc(book).delete();

        return { message: "Book moved to likedBooks successfully." };
    } catch (error) {
        logger.error("Error moving book to likedBooks", error);
        throw new HttpsError("internal", "Failed to move book to likedBooks.");
    }
});

exports.dislikeBook = onCall((request) => {
    // This function will handle the disliking of a book
    // it must remove the book from the queue and add it to the disliked books
    // then it updates the users subject keywords

  });

exports.fetchBooks = onCall(async (request) => {
    // this function will handle the fetching of books
    // it will fetch books from OpenLibrary API based on the users subject keywords
    // it will return a list of books to the user and check if they are already in the queue.
    
});

exports.updateSubjectKeywords = onDocumentCreated(
    "users/{userId}/likedBooks/{bookId}",
    async (event) => {
        const snapshot = event.data; // Access the document snapshot
        const context = event.params; // Access the context parameters
        const userId = context.userId; // Extract userId from the document path
        const likedBooksRef = db.collection("users").doc(userId).collection("likedBooks");
        const userDocRef = db.collection("users").doc(userId);

        try {
            // Fetch the liked books
            const likedBooksSnapshot = await likedBooksRef.orderBy("timestamp", "desc").get();
            if (likedBooksSnapshot.empty) {
                logger.log(`No liked books found for user ${userId}`);
                return;
            }

            const keywordScores = {};
            likedBooksSnapshot.forEach((doc) => {
                const book = doc.data();
                if (book.subjects) {
                    book.subjects.forEach((subject) => {
                        keywordScores[subject] = (keywordScores[subject] || 0) + 1;
                    });
                }
            });

            // Sort keywords by score and take the top 5
            const topKeywords = Object.entries(keywordScores)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 5)
                .map(([keyword]) => keyword);

            // Update the user's subject keywords
            await userDocRef.update({ subjectKeywords: topKeywords });

            logger.log(`Subject keywords updated successfully for user ${userId}`, topKeywords);
        } catch (error) {
            logger.error(`Error updating subject keywords for user ${userId}`, error);
        }
    }
);

exports.userSetup = onCall(async (request, response) => {
    // this function will handle the fetching of trending books to setup the user
    // first it must fetch the trending books from OpenLibrary API
    // then it needs to get more detailed info about each book
    // finally it will store the books in the users queue
    const trendingBooksUrl = "https://openlibrary.org/trending/yearly.json";
    try {
        const openLibResponse = await axios.get(trendingBooksUrl);
        var trendingBooks = openLibResponse.data.works || []; // Extract books from response
        const user = request.data.user; // Assuming user is passed in request
        if (!user) {
            throw new HttpsError("invalid-argument", "Missing user param.");
        }
        // cut down the number of books to 10
        trendingBooks = trendingBooks.slice(0, 10);
        // Map to extract relevant fields
        const formattedBooks = trendingBooks.map((book) => ({
            title: book.title,
            authors: book.author_name || [],
            publishYear: book.first_publish_year || null,
            coverEditionKey: book.cover_edition_key || null,
            author_key: book.author_key || [],
            coverId: book.cover_i || null,
            workKey: book.key,
        }));

        // Fetch detailed info for each book
        const detailedBooks = await Promise.all(
            formattedBooks.map(async (book) => {
                const bookUrl = `https://openlibrary.org${book.workKey}.json`;
                const bookResponse = await axios.get(bookUrl);
                return {
                    ...book,
                    subjects: bookResponse.data.subjects || [],
                    description: bookResponse.data.description?.value || "",
                };
            })
        );

        const userQueueRef = db.collection("users").doc(user).collection("books");

        // Store each book as a separate document
        const batch = db.batch();
        detailedBooks.forEach((book) => {
            const bookDocRef = userQueueRef.doc(); // Auto-generate document ID
            batch.set(bookDocRef, book);
        });
        await batch.commit();
        logger.log(`Trending books stored for user ${user.uid}`);
        return ("Trending books stored successfully.");
    } catch (error) {
        logger.error("Error fetching or storing trending books", error);
        return("Trending books stored unsuccessfully.");
    }
});
