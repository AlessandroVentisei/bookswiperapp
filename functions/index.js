/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios"); // Add axios for HTTP requests
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const functions = require("firebase-functions");

initializeApp(); // Initialize Firebase Admin SDK
const db = getFirestore(); // Get Firestore instance

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

exports.grabTrendingBooks = functions.https.onRequest(async (req, res) => {
    // [START grab_trending_books]
    const trendingBooksUrl = "https://openlibrary.org/trending/yearly.json";
    try {
        const response = await axios.get(trendingBooksUrl);
        const trendingBooks = response.data.works || []; // Extract books from response
        const user = req.body["user"]; // Assuming user is passed in request
        if (!user) {
            res.status(401).send("Unauthorized: User not found.");
            return;
        }
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

        const userQueueRef = db.collection("queue").doc(user).collection("books");

        // Store each book as a separate document
        const batch = db.batch();
        formattedBooks.forEach((book) => {
            const bookDocRef = userQueueRef.doc(); // Auto-generate document ID
            batch.set(bookDocRef, book);
        });
        await batch.commit();

        logger.log(`Trending books stored for user ${user.uid}`);
        res.status(200).send("Trending books stored successfully.");
    } catch (error) {
        logger.error("Error fetching or storing trending books", error);
        res.status(400).send("Trending books stored unsuccessfully.");
    }
    // [END grab_trending_books]
});
