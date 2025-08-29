const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
const fs = require('fs');
const path = require('path');
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const functions = require("firebase-functions");
const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { user } = require("firebase-functions/v1/auth");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { shuffleArray, fetchBookshopCover, getMostRecentEdition } = require("./edition_functions.js");
const { getGeminiAuthorSuggestions, enrichAuthorsWithOpenLibrary } = require('./author_functions.js');
const { url } = require("inspector");
// Switch to Genkit Google AI plugin and model exports
const { googleAI } = require('@genkit-ai/googleai');
const { genkit, z } = require('genkit');

// Load environment variables from .env file for local development
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
}

initializeApp();
const db = getFirestore();

// Try multiple possible environment variable names
const IBSNkey = process.env.ISBN_API_KEY || process.env.isbn || functions.config().isbn?.key;
let axiosConfig = {
  method: 'get',
  maxBodyLength: Infinity,
  headers: { 
    'Authorization': IBSNkey
  }
};


const ai = genkit({
    // Use an absolute path so Jest/Cloud Functions can always find prompts
    promptDir: path.join(__dirname, 'prompts'),
    plugins: [
        googleAI({
            apiKey: process.env.GEMINI_API_KEY,
        }),
    ],
});


logger.log("Environment check", {
    nodeEnv: process.env.NODE_ENV,
    isbnKey: IBSNkey ? "Present" : "Missing",
    geminiKey: process.env.GEMINI_API_KEY ? "Present" : "Missing"
});

// Sanitize objects before writing to Firestore:
// - Remove any keys starting with "__" (reserved by Firestore, e.g. __name__, __src__)
// - Drop undefined values
// - Replace non-finite numbers with null
function sanitizeForFirestore(value) {
    if (Array.isArray(value)) {
        return value.map((v) => sanitizeForFirestore(v));
    }
    if (value && typeof value === 'object') {
        const out = {};
        for (const [k, v] of Object.entries(value)) {
            // Skip reserved keys
            if (typeof k === 'string' && k.startsWith('__')) continue;
            const sv = sanitizeForFirestore(v);
            // Skip undefined values
            if (sv === undefined) continue;
            out[k] = sv;
        }
        return out;
    }
    if (typeof value === 'number' && !Number.isFinite(value)) return null;
    // Firestore doesn't accept undefined
    if (value === undefined) return null;
    return value;
}

// Run once a week at local midnight (Europe/London) to reset aiSummaryUsage safely and efficiently
// Trigger/rerun from Cloud Scheduler if needed.
exports.accountcleanup = onSchedule({ schedule: "0 0 * * 1", timeZone: "Europe/London" }, async () => {
    const pageSize = 500; // paginate to control memory/CPU
    let lastDoc = null;
    let total = 0;

    const writer = db.bulkWriter();
    writer.onWriteError((error) => {
        logger.error("BulkWriter write error", error);
        // Retry safe errors
        return true;
    });

    try {
        // Page through all users ordered by doc name for consistent pagination
        // eslint-disable-next-line no-constant-condition
        while (true) {
            let query = db.collection('users').orderBy('__name__').limit(pageSize);
            if (lastDoc) query = query.startAfter(lastDoc);
            const snap = await query.get();
            if (snap.empty) break;

            snap.docs.forEach((doc) => {
                writer.update(doc.ref, {
                    aiSummariesCount: 0,
                    lastAiSummariesResetAt: FieldValue.serverTimestamp(),
                });
                total += 1;
            });

            lastDoc = snap.docs[snap.docs.length - 1];
        }

        await writer.close();
        logger.log(`User cleanup finished; reset aiSummariesCount for ${total} users`);
    } catch (err) {
        try { await writer.close(); } catch (_) {}
        logger.error("User cleanup failed", err);
        throw err;
    }
});

exports.fetchAiSummary = onCall(async (request, response) => {
    const user = request.data.user;
    const key = request.data.key
    const title = request.data.title;
    const author = request.data.author || '';
    const bookDoc = await db.collection("users").doc(user).collection("books").where("key", "==", key).limit(1).get();
    try {
        if (bookDoc.empty) {
            throw new HttpsError("not-found", "Book not found in queue.");
        }
        if(bookDoc.docs[0].data().ai_summary_fetched == true) {
            throw new HttpsError("failed-precondition", "AI summary already fetched.");
        }
        const { data } = await axios.request('https://api-d7b62b.stack.tryrelevance.com/latest/studios/ef7579ab-3ad5-4b21-9c89-e4f0d2b4ecf2/trigger_webhook?project=2e2e491cd534-4180-a704-312a31299fd9', {
            method: "POST",
            headers: {"Content-Type":"application/json","Authorization":process.env.RELEVANCE_AI},
            data: {"title":title,"author":author}
        });
                // Some AI providers return a JSON string in `llm_answer`. Normalize it to a clean object.
                const raw = (data && typeof data === 'object' && 'llm_answer' in data)
                    ? data.llm_answer
                    : data;

                let summary;
                try {
                    if (typeof raw === 'string') {
                        // Strip optional code fences and parse JSON if possible
                        const stripped = raw.trim()
                            .replace(/^```(?:json)?\s*/i, '')
                            .replace(/```\s*$/i, '');
                        summary = JSON.parse(stripped);
                    } else if (raw && typeof raw === 'object') {
                        summary = raw;
                    } else {
                        summary = { text: String(raw ?? '') };
                    }
                } catch (_parseErr) {
                    // Fallback: unescape common sequences and return as plain text
                    const text = String(raw ?? '')
                        .replace(/\\n/g, '\n')
                        .replace(/\\\"/g, '"')
                        .replace(/^['"`]|['"`]$/g, '');
                    summary = { text };
                }
                console.log(summary);
                const search_result_organic = data.search_result_organic || [];
                await bookDoc.docs[0].ref.update({ ai_summary: summary, ai_summary_fetched: true, search_result_organic: search_result_organic });
                return "Summary fetched and stored.";
    } catch (e) {
        console.log(e);
        throw new HttpsError('internal', 'Error fetching AI summary', String(e?.message || e));
    }
});

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
    const dislikedBooksRef = db.collection("users").doc(user).collection("dislikedBooks");

    try {
        // Get the book document by checking both queue and dislikedBooks.
        var bookDoc = await userQueueRef.doc(book).get();
        var loc = "books";
        if (!bookDoc.exists) {
            bookDoc = await dislikedBooksRef.doc(book).get();
            loc = "dislikedBooks";
            if (!bookDoc.exists) {
                throw new HttpsError("not-found", "Book not found in queue or dislikedBooks.");
            }
        }

        const bookData = bookDoc.data();

        // Add the book to the likedBooks collection
        await likedBooksRef.doc(book).set(bookData);

        // Remove the book from loc
        if (loc === "books") {
            await userQueueRef.doc(book).delete();
        } else if (loc === "dislikedBooks") {
            await dislikedBooksRef.doc(book).delete();
        }

        // Count liked books and update shortlist every 5 likes
        const likedBooksCount = (await likedBooksRef.get()).size;
        if (likedBooksCount % 5 == 0) {
            await updateShortlistedAuthorsForUser(user);
        }
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
    const likedBooksRef = db.collection("users").doc(user).collection("likedBooks");

    try {
        // Get the book document
        const bookDoc = await userQueueRef.doc(book).get();
        var loc = "books";
        if (!bookDoc.exists) {
            bookDoc = await likedBooksRef.doc(book).get();
            loc = "likedBooks";
            if (!bookDoc.exists) {
                throw new HttpsError("not-found", "Book not found in queue or likedBooks.");
            }
        }

        const bookData = bookDoc.data();

        // Add the book to the dislikedBooks collection
        await dislikedBooksRef.doc(book).set(bookData);

        // Remove the book from loc
        if (loc === "books") {
            await userQueueRef.doc(book).delete();
        } else if (loc === "likedBooks") {
            await likedBooksRef.doc(book).delete();
        }

        return { message: "Book moved to dislikedBooks successfully." };
    } catch (error) {
        logger.error("Error moving book to dislikedBooks", error);
        throw new HttpsError("internal", "Failed to move book to dislikedBooks.");
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
  let newBooks = [];
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
  const subjectKeywords = userData.subjectKeywords.slice(0, 5) || [];
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
  const enrichedBooks = [];
  var output = [];
  if (process.env.GEMINI_API_KEY) {
    try {
      // Look up by prompt ID (filename without extension)
      const fetchPrompt = ai.prompt('fetchBooks');
      ({output} = await fetchPrompt({
        num: 10,
        books: likedBooksSnapshot.docs
          .slice(0, 5)
          .map(doc => doc.data().title)
          .join(', '),
      }));
      // console.log('AI Output:', output);
    } catch (error) {
      logger.error(`Error generating new AI-generated recommendations for user ${userId}:`, error);
    }
  } else {
    logger.log('GEMINI_API_KEY not set; skipping AI-generated recommendations.');
  }

    // Parallel OpenLibrary lookups for AI recommendations
    if (output.length > 0) {
        const aiResults = await Promise.allSettled(
            output.map(async (rec) => {
                const bookTitle = rec.title || '';
                if (!bookTitle) return null;
                const authorParam = rec.author ? `&author=${encodeURIComponent(rec.author)}` : '';
                const searchUrl = `https://openlibrary.org/search.json?title=${encodeURIComponent(bookTitle)}${authorParam}&limit=10&language=eng`;
                try {
                    const resp = await axios.get(searchUrl);
                    const docs = resp.data?.docs || [];
                    if (!docs.length) return null;
                    let chosen = docs.find(d => (d.title || '').toLowerCase() === bookTitle.toLowerCase());
                    if (!chosen && rec.author) {
                        const recAuthorLc = rec.author.toLowerCase();
                        chosen = docs.find(d => Array.isArray(d.author_name) && d.author_name.some(a => a.toLowerCase() === recAuthorLc));
                    }
                    chosen = chosen || docs[0];
                    return {
                        ...chosen,
                        createdAt: new Date(),
                        reason_for_recommendation: rec.reason_for_recommendation,
                    };
                } catch (err) {
                    logger.error(`Error fetching OpenLibrary data for AI title "${bookTitle}"`, err);
                    return null;
                }
            })
        );
        aiResults.forEach(r => { if (r.status === 'fulfilled' && r.value) enrichedBooks.push(r.value); });
    }

    try {
        // Fetch books based on subject keywords (parallelized per keyword)
        const books = [];
        const pageSize = 20; // Number of books to fetch per request
        const keywordFetches = await Promise.allSettled(
            subjectKeywords.map(async (keyword) => {
                try {
                    const formattedKeyword = keyword.replace(/\s+/g, "_").toLowerCase();
                    // First, get the work_count for this subject
                    const subjectUrl = `https://openlibrary.org/subjects/${formattedKeyword}.json?details=true`;
                    const subjectResponse = await axios.get(subjectUrl);
                    const workCount = subjectResponse.data.work_count || 0;
                    if (workCount === 0) return [];
                    // Pick a random offset between 0 and top 1% of workCount (limit to 12 per OpenLibrary API)
                    const maxOffset = Math.max(0, Math.round(workCount / 100));
                    const randomOffset = Math.floor(Math.random() * (maxOffset + 1));
                    // Fetch a random page of works for this subject
                    const worksUrl = `https://openlibrary.org/subjects/${formattedKeyword}.json?details=true&offset=${randomOffset}`;
                    const worksResponse = await axios.get(worksUrl);
                    const bookData = worksResponse.data['works'] || [];
                    // Filter out books published before 1980s (could be user parameter in the future)
                    const filtered = bookData.filter((b) => (b.first_publish_year || 0) > 1980);
                    const formattedBooks = filtered.map((book, indx) => ({
                        ...book,
                        createdAt: new Date(),
                    }));
                    return formattedBooks;
                } catch (error) {
                    logger.error(`Error fetching books for keyword "${keyword}" for user ${userId}`, error);
                    return [];
                }
            })
        );
        keywordFetches.forEach((res) => {
            if (res.status === 'fulfilled' && Array.isArray(res.value)) {
                books.push(...res.value);
            }
        });
    // Filter out books that are already in the queue/liked/disliked
    const existingQueueBooks = queueSnapshot.docs.map((doc) => doc.data().key);
    const existingLikedBooks = likedBooksSnapshot.docs.map((doc) => doc.data().key);
    const existingDislikedBooks = dislikedBooksSnapshot.docs.map((doc) => doc.data().key);
    const existingBooks = [...existingQueueBooks, ...existingLikedBooks, ...existingDislikedBooks];
    newBooks = books.filter((book) => !existingBooks.includes(book.key));

     // Enrich and filter books (parallelized per book)
        const enrichResults = await Promise.allSettled(
            newBooks.map(async (book) => {
                try {
                    // Fetch editions for the book
                    const editionsUrl = `https://openlibrary.org${book.key}/editions.json`;
                    const editionsResponse = await axios.get(editionsUrl);
                    const editionsData = editionsResponse.data;
                    if (!editionsData || !editionsData.entries || editionsData.entries.length === 0) return null;
                    const firstEdition = getMostRecentEdition(editionsData.entries);
                    if (!firstEdition) return null;

                    // Fetch all author details in parallel and attach to authors array
                    let authors = book.authors;
                    if (Array.isArray(authors)) {
                        authors = await Promise.all(
                            authors.map(async (author) => {
                                try {
                                    const authorKey = author.key || (author.author && author.author.key);
                                    if (authorKey) {
                                        const authorUrl = `https://openlibrary.org${authorKey}.json`;
                                        const authorResponse = await axios.get(authorUrl);
                                        return { ...author, details: authorResponse.data };
                                    }
                                } catch (_) {}
                                return author;
                            })
                        );
                    }

                    return { ...book, ...firstEdition, authors };
                } catch (error) {
                    logger.error(`Error enriching book ${book.key}`, error);
                    return null;
                }
            })
        );
        enrichResults.forEach((r) => {
            if (r.status === 'fulfilled' && r.value) {
                enrichedBooks.push(r.value);
            }
        });

    if (enrichedBooks.length === 0) {
        logger.log(`No enriched books found for user ${userId}`);
        await userDocRef.update({ isUpdating: false });
        return;
    }
    } catch (error) {
    logger.error(`Error fetching books for user ${userId}`, error);
    await userDocRef.update({ isUpdating: false });
    throw new HttpsError("internal", "Failed to fetch and enrich books.");
  }

    // insert AI recommended books
    if (enrichedBooks.length > 0) {
        newBooks = [...enrichedBooks, ...newBooks];
    }
  // shuffle the newBooks array
  shuffleArray(newBooks);

    await Promise.all(newBooks.map(async (book, indx) => {
        // Derive author name string for cover fetching
        let authorName = '';
        try {
            if (Array.isArray(book.authors) && book.authors.length > 0) {
                const a0 = book.authors[0];
                if (typeof a0 === 'string') authorName = a0;
                else if (a0?.details?.name) authorName = a0.details.name;
                else if (a0?.name) authorName = a0.name;
                else if (a0?.author?.name) authorName = a0.author.name;
            }
        } catch {}
        book.bookshop_cover_url = await fetchBookshopCover(book.title, authorName);
    }));
    // add indexes for each entry for ordering in queue
    newBooks = newBooks.map((book, indx) => ({
        ...book,
        index: userCurrentIndex + indx
    }));
    // Sanitize before writing
    const batch = db.batch();
    newBooks.forEach((book) => {
        const sanitized = sanitizeForFirestore(book);
        const bookDocRef = queueRef.doc();
        batch.set(bookDocRef, sanitized);
    });
    await batch.commit();
    await userDocRef.update({ isUpdating: false, currentIndex: userCurrentIndex });
    logger.log(`Fetched and stored ${newBooks.length} new books for user ${userId}`);
    return { message: "Books fetched and stored successfully." };
});

exports.fetchAuthorInfo = onCall(async (request) => {
    const authorName = request.data.authorName;
    
    if (!authorName) {
        throw new HttpsError("invalid-argument", "Missing authorName parameter");
    }
    
    const authorInfo = {};
    
    // Log the API key status for debugging
    logger.log("API Key check", {
        isbnKeyPresent: IBSNkey ? "Yes" : "No",
        isbnKeyLength: IBSNkey ? IBSNkey.length : 0,
        authorName: authorName
    });
    
    if (!IBSNkey) {
        logger.error("ISBNdb API key not configured");
        throw new HttpsError("failed-precondition", "ISBNdb API key not configured");
    }
    
    // Fetch author information from ISBNdb
    try {
        const encodedAuthorName = encodeURIComponent(authorName);
        const authorUrl = `https://api2.isbndb.com/author/${encodedAuthorName}?page=1&pageSize=20&language=en`;
        
        logger.log(`Fetching author info from: ${authorUrl}`);
        
        const response = await axios.request({ 
            ...axiosConfig, 
            url: authorUrl,
        });
        
        authorInfo.details = response.data;
        logger.log(`Successfully fetched author info for ${authorName}`, {
            hasAuthor: !!response.data.author,
            responseKeys: Object.keys(response.data)
        });
    } catch (error) {
        logger.error(`Error fetching author info for ${authorName}`, error);
    }
    return authorInfo;
});


async function updateShortlistedAuthorsForUser(userId) {
    const likedBooksRef = db.collection("users").doc(userId).collection("likedBooks");
    const userDocRef = db.collection("users").doc(userId);
    try {
        const likedBooksSnapshot = await likedBooksRef.get();
        if (likedBooksSnapshot.empty) return;
        // Tally authors
        const authorCounts = {};
        likedBooksSnapshot.forEach(doc => {
            const book = doc.data();
            if (Array.isArray(book.authors)) {
                book.authors.forEach(author => {
                    const authorKey = author.key || (author.author && author.author.key);
                    const authorName = author.details?.name || author.name || null;
                    if (authorKey && authorName) {
                        const id = `${authorKey}|${authorName}`;
                        if (!authorCounts[id]) {
                            authorCounts[id] = { key: authorKey, name: authorName, count: 0 };
                        }
                        authorCounts[id].count += 1;
                    }
                });
            }
        });
        // Sort and take top 5
        const topAuthors = Object.values(authorCounts)
            .sort((a, b) => b.count - a.count)
            .slice(0, 5);
        // get more suggestions from Gemini
        const userDoc = await userDocRef.get();
        const subjectKeywords = userDoc.data().subjectKeywords || [];
        const likedAuthors = topAuthors.map(author => ({ name: author.name, key: author.key }));
        let geminiSuggestions = [];
        try {
            geminiSuggestions = await getGeminiAuthorSuggestions(likedAuthors, subjectKeywords);
        } catch (e) {
            logger.error('Gemini suggestion error', e);
        }
        // Enrich Gemini suggestions with Open Library data
        let enrichedSuggestions = [];
        try {
            enrichedSuggestions = await enrichAuthorsWithOpenLibrary(geminiSuggestions);
        } catch (e) {
            logger.error('OpenLibrary enrichment error', e);
        }
        // Combine top authors with enriched suggestions, avoiding duplicates
        const allAuthors = [...topAuthors];
        enrichedSuggestions.forEach(suggestion => {
            if (!allAuthors.some(a =>
                (a.key && suggestion.key && a.key === suggestion.key) ||
                a.name.toLowerCase() === suggestion.name.toLowerCase()
            )) {
                allAuthors.push(suggestion);
            }
        });
        await userDocRef.update({ shortlistedAuthors: allAuthors });
        logger.log(`Shortlisted authors updated for user ${userId}`, { shortlistedAuthors: allAuthors });
    } catch (error) {
        logger.error(`Error updating shortlisted authors for user ${userId}`, error);
    }
}
