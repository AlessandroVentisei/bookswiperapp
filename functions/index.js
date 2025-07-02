const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios"); // Add axios for HTTP requests
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const functions = require("firebase-functions");
const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { user } = require("firebase-functions/v1/auth");
const { getMostRecentEdition, parseYear, fetchBookshopCover } = require("./edition_functions.js");

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

exports.updateSubjectKeywords = onDocumentCreated(
    "users/{userId}/likedBooks/{bookId}",
    async (event) => {
        const snapshot = event.data;
        const context = event.params;
        const userId = context.userId;
        const likedBooksRef = db.collection("users").doc(userId).collection("likedBooks");
        const dislikedBooksRef = db.collection("users").doc(userId).collection("dislikedBooks");
        const userDocRef = db.collection("users").doc(userId);

        try {
            // Fetch liked and disliked books
            const [likedBooksSnapshot, dislikedBooksSnapshot] = await Promise.all([
                likedBooksRef.orderBy("createdAt", "desc").limit(200).get(),
                dislikedBooksRef.limit(200).get()
            ]);
            if (likedBooksSnapshot.empty) {
                logger.log(`No liked books found for user ${userId}`);
                return;
            }

            // Build a set of disliked subjects
            const dislikedSubjects = {};
            dislikedBooksSnapshot.forEach((doc) => {
                const book = doc.data();
                if (book.subject) {
                    book.subject.forEach((subject) => {
                        dislikedSubjects[subject] = (dislikedSubjects[subject] || 0) + 1;
                    });
                }
            });

            // Assign scores to keywords from liked books, prioritizing recent ones
            const keywordScores = {};
            const decadeCounts = {};
            const likedDocs = likedBooksSnapshot.docs;
            const total = likedDocs.length;
            likedDocs.forEach((doc, idx) => {
                const book = doc.data();
                // More recent books get higher weight
                const weight = total - idx;
                if (book.subject) {
                    book.subject.forEach((subject) => {
                        keywordScores[subject] = (keywordScores[subject] || 0) + weight;
                    });
                }
                // Count by decade for favorite publishing period
                if (book.first_publish_year) {
                    const year = parseInt(book.first_publish_year);
                    if (!isNaN(year)) {
                        const decade = Math.floor(year / 10) * 10;
                        decadeCounts[decade] = (decadeCounts[decade] || 0) + 1;
                    }
                }
            });

            // Deprioritize keywords found in disliked books
            Object.keys(dislikedSubjects).forEach((subject) => {
                if (keywordScores[subject]) {
                    keywordScores[subject] -= dislikedSubjects[subject];
                }
            });

            // Sort keywords by score and take the top 5
            const topKeywords = Object.entries(keywordScores)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 5)
                .map(([keyword]) => keyword);

            // Find favourite publishing period (decade with most liked books)
            let favouritePublishingPeriod = null;
            if (Object.keys(decadeCounts).length > 0) {
                const topDecade = Object.entries(decadeCounts)
                    .sort((a, b) => b[1] - a[1])[0][0];
                favouritePublishingPeriod = `${topDecade}s`;
            }

            await userDocRef.update({ subjectKeywords: topKeywords, favouritePublishingPeriod });

            logger.log(`Subject keywords and favourite publishing period updated for user ${userId}`, { topKeywords, favouritePublishingPeriod });
        } catch (error) {
            logger.error(`Error updating subject keywords for user ${userId}`, error);
        }
    }
);

exports.userSetup = onCall(async (request) => {
    // this function will handle the fetching of trending books to setup the user
    // first it must fetch the trending books from OpenLibrary API
    // then it needs to get more detailed info about each book
    // finally it will store the books in the users queue
    const trendingBooksUrl = "https://openlibrary.org/works/OL5736965W.json";
    try {
        const openLibResponse = await axios.get(trendingBooksUrl);
        var trendingBooks = openLibResponse.data.works || []; // Extract books from response
        const user = request.data.user; // Assuming user is passed in request
        if (!user) {
            throw new HttpsError("invalid-argument", "Missing user param.");
        }
        // cut down the number of books to 10
        trendingBooks = trendingBooks.slice(0, 10);
        const formattedBooks = bookData.map((book) => ({
                ...book
            }));

        const detailedBooks = await Promise.all(
            formattedBooks.map(async (book) => {
                const bookUrl = `https://openlibrary.org${book.key}.json`;
                const bookResponse = await axios.get(bookUrl);
                return {
                    ...book,
                    ...bookResponse.data,
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

exports.fetchAndEnrichBooks = onCall(async (request) => {
    // Combined fetch and enrich logic
    const userId = request.data.userId; // Extract userId from the request
    const userDocRef = db.collection("users").doc(userId);
    const queueRef = db.collection("users").doc(userId).collection("books");
    const likedBooksRef = db.collection("users").doc(userId).collection("likedBooks");
    const dislikedBooksRef = db.collection("users").doc(userId).collection("dislikedBooks");
    // Check if the queue has less than 10 books
    const queueSnapshot = await queueRef.get();
    const likedBooksSnapshot = await likedBooksRef.get();
    const dislikedBooksSnapshot = await dislikedBooksRef.get();
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
    var userCurrentIndex = userData.currentIndex || 0;
    if (userCurrentIndex === undefined || userCurrentIndex === null) {
        await userDocRef.update({ currentIndex: 0 });
        userCurrentIndex = 0;
    }
    if (subjectKeywords.length === 0) {
        logger.log(`No subject keywords found for user ${userId}`);
        return;
    }
    if (userData.isUpdating == true || userData.isUpdating == "true") {
        logger.log(`User ${userId} is already updating the queue. ${userData.isUpdating}`);
        return;
    }
    await userDocRef.update({ isUpdating: true });

    // Fetch books based on subject keywords
    const books = [];
    for (const keyword of subjectKeywords) {
        const formattedKeyword = keyword.replace(/\s+/g, "_").toLowerCase();
        // First, get the work_count for this subject
        const subjectUrl = `https://openlibrary.org/subjects/${formattedKeyword}.json?details=true`;
        const subjectResponse = await axios.get(subjectUrl);
        const workCount = subjectResponse.data.work_count || 0;
        if (workCount === 0) {continue};
        // Pick a random offset between 0 and top 1% of workCount (limit to 12 per OpenLibrary API)
        const maxOffset = Math.max(0, Math.round(workCount/100));
        const randomOffset = Math.floor(Math.random() * (maxOffset + 1));
        // Fetch a random page of works for this subject
        const worksUrl = `https://openlibrary.org/subjects/${formattedKeyword}.json?details=true&offset=${randomOffset}`;
        const worksResponse = await axios.get(worksUrl);
        const bookData = worksResponse.data['works'] || [];
        bookData.filter((book) => book.first_publish_year > 1980); // Filter out books published before 1980s (could be user parameter in the future)
        const formattedBooks = bookData.map((book, indx) => ({
            ...book,
            createdAt: new Date(),
            index: userCurrentIndex + indx
        }));
        userCurrentIndex += formattedBooks.length;
        books.push(...formattedBooks);
    }
    // Filter out books that are already in the queue/liked/disliked
    console.log(`Fetched ${books.length} books for user ${userId} with keywords: ${subjectKeywords.join(", ")}`);
    const existingQueueBooks = queueSnapshot.docs.map((doc) => doc.data().key);
    const existingLikedBooks = likedBooksSnapshot.docs.map((doc) => doc.data().key);
    const existingDislikedBooks = dislikedBooksSnapshot.docs.map((doc) => doc.data().key);
    const existingBooks = [...existingQueueBooks, ...existingLikedBooks, ...existingDislikedBooks];
    let newBooks = books.filter((book) => !existingBooks.includes(book.key));
    if (newBooks.length === 0) {
        logger.log(`No new books found for user ${userId}`);
        await userDocRef.update({ isUpdating: false });
        return;
    }
    // Enrich and filter books
    const enrichedBooks = [];
    for (const book of newBooks) {
        try {
            // Fetch editions for the book
            const editionsUrl = `https://openlibrary.org${book.key}/editions.json`;
            const editionsResponse = await axios.get(editionsUrl);
            const editionsData = editionsResponse.data;
            if (!editionsData || !editionsData.entries || editionsData.entries.length === 0) continue;
            const firstEdition = getMostRecentEdition(editionsData.entries);
            if(!firstEdition) continue;
            // Fetch all author details in parallel and attach to authors array
            if (Array.isArray(book.authors)) {
                book.authors = await Promise.all(
                    book.authors.map(async (author) => {
                        // Support both { key } and { author: { key } }
                        const authorKey = author.key || (author.author && author.author.key);
                        if (authorKey) {
                            const authorUrl = `https://openlibrary.org${authorKey}.json`;
                            const authorResponse = await axios.get(authorUrl);
                            return { ...author, details: authorResponse.data };
                        }
                        return author;
                    })
                );
            }
            // Scrape Bookshop.org for a cover image
            const bookshopCover = await fetchBookshopCover(book.title, book.authors[0]?.name);
            book.bookshop_cover_url = bookshopCover || null;
            enrichedBooks.push({ ...book, ...firstEdition, authors: book.authors }); } catch (error) {
            logger.error(`Error enriching book ${book.key}`, error);
        }
    }

    if (enrichedBooks.length === 0) {
        logger.log(`No enriched books found for user ${userId}`);
        await userDocRef.update({ isUpdating: false });
        return;
    }
    
    // Batch write enriched books
    const batch = db.batch();
    enrichedBooks.forEach((book) => {
        // Remove 'availability' field before writing
        const { availability, ...cleanedBook } = book;
        const bookDocRef = queueRef.doc();
        batch.set(bookDocRef, cleanedBook);
    });
    await batch.commit();
    await userDocRef.update({ isUpdating: false, currentIndex: userCurrentIndex });
    logger.log(`Fetched and stored ${enrichedBooks.length} enriched books for user ${userId}`);
    return { message: "Books fetched, enriched, and stored successfully."};
});
