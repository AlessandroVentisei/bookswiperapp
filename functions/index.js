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
const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");

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

exports.dislikeBook = onCall(async (request) => {
    // This function will handle the disliking of a book
    // it must remove the book from the queue and add it to the disliked books
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
    const dislikedBooksRef = db.collection("users").doc(user).collection("dislikedBooks");

    try {
        // Get the book document
        const bookDoc = await userQueueRef.doc(book).get();
        if (!bookDoc.exists) {
            throw new HttpsError("not-found", "Book not found in queue.");
        }

        const bookData = bookDoc.data();

        // Add the book to the likedBooks collection
        await dislikedBooksRef.doc(book).set(bookData);

        // Remove the book from the queue
        await userQueueRef.doc(book).delete();

        return { message: "Book moved to likedBooks successfully." };
    } catch (error) {
        logger.error("Error moving book to likedBooks", error);
        throw new HttpsError("internal", "Failed to move book to likedBooks.");
    }
  });

exports.enrichQueue = onDocumentCreated("users/{userId}/books/{bookId}", async (event) => {
    // this function will handle the enrichment of a book
    // it will fetch more detailed info about the book from OpenLibrary API
    // it will update the book in the queue with the new info
    const userId = event.params.userId; // Extract userId from the document path
    const bookId = event.params.bookId; // Extract bookId from the document path
    // Get the queue reference
    const queueRef = db.collection("users").doc(userId).collection("books");
    const bookDocRef = queueRef.doc(bookId);
    const bookDoc = await bookDocRef.get();
    if (!bookDoc.exists) {
        logger.error(`Book document not found for user ${userId} and book ${bookId}`);
        return;
    }
    const bookData = bookDoc.data();
    const openLibUrl = `https://openlibrary.org${bookData.workKey}.json`;
    try {
        const response = await axios.get(openLibUrl);
        const detailedBookData = response.data;
        await bookDocRef.update({
            subjects: detailedBookData.subjects || [],
            description: detailedBookData.description?.value || "",
        });

        const editions = await axios.get(`https://openlibrary.org${bookData.workKey}/editions.json`);
        const editionsData = editions.data;
        // extract ISBN13, languages.key, subtitle, published_date, publisher, and subjects from the first edition.
        const firstEdition = editionsData.entries[0];
        const isbn13 = firstEdition?.isbn_13 || [];
        const languages = firstEdition?.languages || [];
        const subtitle = firstEdition?.subtitle || "";
        const publishedDate = firstEdition?.publish_date || "";
        const publisher = firstEdition?.publishers || [];
        const subjects = firstEdition?.subjects || [];
        const pagination = firstEdition?.pagination || "";
        const languageKeys = languages.map((language) => language.key);
        // delete book from queue if there is no isbn13 or the language.key doesn't contain "/languages/eng"
        if (isbn13.length === 0 || languageKeys.length === 0) {
            await bookDocRef.delete();
            logger.log(`Book document deleted for user ${userId} and book ${bookId}`);
            return;
        }
        // update the book document with the new data
        await bookDocRef.update({
            isbn13: isbn13,
            languages: languageKeys,
            subtitle: subtitle,
            publishedDate: publishedDate,
            publisher: publisher,
            subjects_edition: subjects,
            pagination: pagination,
        });
        logger.log(`Book document enriched for user ${userId} and book ${bookId}`);
    } catch (error) {
        logger.error(`Error enriching book document for user ${userId} and book ${bookId}`, error);
    }
}
);

exports.fetchBooks = onCall(async (request) => {
    // this function will handle the fetching of books
    // it will fetch books from OpenLibrary API based on the users subject keywords
    // it will return a list of books to the user and check if they are already in the queue.
    // It needs to be called in the event that there are less than 10 books in the explore queue.
    // the app side will call this function after every 5 swipes has taken place.
    const userId = request.userId; // Extract userId from the request
    const userDocRef = db.collection("users").doc(userId);
    queueRef = db.collection("users").doc(userId).collection("books");
    likedBooksRef = db.collection("users").doc(userId).collection("likedBooks");
    dislikedBooksRef = db.collection("users").doc(userId).collection("dislikedBooks")
    //check if the queue has less than 10 books
    const queueSnapshot = await queueRef.get();
    const likedBooksSnapshot = await likedBooksRef.get();
    const dislikedBooksSnapshot = await dislikedBooksRef.get();
    // Check if the queue has less than 10 books
    if (queueSnapshot.docs.length >= 10) {
        logger.log(`User ${userId} already has enough books in the queue.`);
        return;
    }
    const userDoc = await userDocRef.get();
    if (!userDoc.exists) {
        logger.error(`User document not found for user ${userId}`);
        return;
    }
    const userData = userDoc.data();
    const subjectKeywords = userData.subjectKeywords.slice(0, 3) || [];
    if (subjectKeywords.length === 0) {
        logger.log(`No subject keywords found for user ${userId}`);
        return;
    }
    if (userData.isUpdating == true || userData.isUpdating == "true") {
        logger.log(`User ${userId} is already updating the queue. ${userData.isUpdating}`);
        //stop the function.
        return;
    }
    // Set the isUpdating flag to true
    await userDocRef.update({ isUpdating: true });

    // Fetch books based on subject keywords
    const books = [];
    for (const keyword of subjectKeywords) {
        const openLibUrl = `https://openlibrary.org/subjects/${keyword}.json?details=true`;
        try {
            const response = await axios.get(openLibUrl);
            const bookData = response.data['works'] || [];
            // Map to extract relevant fields
            const formattedBooks = bookData.map((book) => ({
                title: book.title,
                authors: book.authors.map((author)=>author?.name) || [],
                author_key: book.authors.map((author)=>author?.key) || "",
                publishYear: book.first_publish_year || null,
                coverEditionKey: book.cover_edition_key || null,
                coverId: book.cover_id || null,
                workKey: book.key,
                subjects: book.subject || [],
                description: book.description?.value || "",
            }));
            books.push(...formattedBooks);
        } catch (error) {
            logger.error(`Error fetching books for keyword ${keyword}`, error);
        }
    }
    // Filter out books that are already in the queue
    const existingQueueBooks = queueSnapshot.docs.map((doc) => doc.data().workKey);
    const existingLikedBooks = likedBooksSnapshot.docs.map((doc) => doc.data().workKey);
    const existingDislikedBooks = dislikedBooksSnapshot.docs.map((doc) => doc.data().workKey);
    // Combine all existing books
    const existingBooks = [...existingQueueBooks, ...existingLikedBooks, ...existingDislikedBooks];
    // Filter.
    const newBooks = books.filter((book) => !existingBooks.includes(book.workKey));
    // filter out books which have no description
    const filteredBooks = newBooks.filter((book) => book.description !== "");
    //randomize the new books
    filteredBooks.sort(() => Math.random() - 0.5);
    // Limit to 10 books
    filteredBooks.splice(10);
    // Check if there are any new books to add
    if (filteredBooks.length === 0) {
        logger.log(`No new books found for user ${userId}`);
        // Set the isUpdating flag to false
        await userDocRef.update({ isUpdating: false });
        return;
    }
    // Store each book as a separate document
    const batch = db.batch();
    filteredBooks.forEach((book) => {
        const bookDocRef = queueRef.doc(); // Auto-generate document ID
        batch.set(bookDocRef, book);
    });
    await batch.commit();
    // Set the isUpdating flag to false
    await userDocRef.update({ isUpdating: false });
    // Log the number of new books added
    logger.log(`Fetched and stored ${filteredBooks.length} new books for user ${userId}`);
    return { message: "Books fetched and stored successfully." };
    
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
            const likedBooksSnapshot = await likedBooksRef.get();
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
