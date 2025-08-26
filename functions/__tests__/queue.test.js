// Jest test for likeBook and fetchBooks Firebase Functions
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
const test = require('firebase-functions-test')({
  projectId: 'matchbook-b610d',
}, "./serviceAccountKey.json");
const admin = require('firebase-admin');
const myFunctions = require('../index');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

describe('Queue Functions', () => {
  let wrappedLikeBook, wrappedFetchAndEnrichBooks, wrappedFetchAuthors;
  let db;

  beforeAll(async () => {
    db = admin.firestore();
    wrappedLikeBook = test.wrap(myFunctions.likeBook);
    wrappedFetchAndEnrichBooks = test.wrap(myFunctions.fetchAndEnrichBooks);
    wrappedFetchAuthors = test.wrap(myFunctions.fetchAuthorInfo);
});

  afterAll(async () => {
    // test.cleanup();
    // Properly clean up the Firebase Admin app to close open handles
    // await Promise.all(admin.apps.map(app => app.delete()));
    /*await db.collection('users').get().then(snapshot => {
      snapshot.forEach(doc => {
        doc.ref.delete();
      });
    });*/
    jest.restoreAllMocks();
  });

  it('should return error if user param is missing in likeBook', async () => {
    await expect(wrappedLikeBook({ book: 'book1' })).rejects.toThrow();
  });

  it('should return error if book param is missing in likeBook', async () => {
    await expect(wrappedLikeBook({ user: 'user1' })).rejects.toThrow();
  });
  /*it('should fetch author info from ISBNdb', async () => {
    const result = await wrappedFetchAuthors({ data: { authorName: 'Stephen King' } });
    expect(result).toBeDefined();
  });*/
  it('should fetch books from the OL database and store in firestore', async () => {
        // Arrange: create user and book in Firestore
    const userId = 'testuser';
    const bookId = 'testbook';
    const workKey = '/works/OL66554W';
    await db.collection('users').doc(userId).set({"username": "testuser", subjectKeywords: ["science-fiction", "non-fiction physics"], fetchedSubjects: [], currentIndex: 0, isUpdating: false });
    await wrappedFetchAndEnrichBooks({ data: { userId } });

  }, 40000);

  /*it('should enrich a book document with OpenLibrary data', async () => {
    // Arrange: create user and book in Firestore
    const userId = 'testuser';
    const bookId = 'testbook';
    const workKey = '/works/OL66554W';
    await db.collection('users').doc(userId).set({"username": "testuser", subjectKeywords: ["test"], fetchedSubjects: [], currentIndex: 0, isUpdating: false });
    // Mock the OpenLibrary API response for the work key
    const keyResponse = require('./keyResponse.json');
    const editionsResponse = require('./editionsResponse.json');
    const subjectsResponse = require('./subjectResponse.json');
    const authorResponse = require('./authorResponse.json');
    const aliceinWonderlandResponse = fs.readFileSync(path.join(__dirname, 'aliceinwonderland.html'), 'utf8');
    // Mock OpenLibrary API responses
    axios.get.mockImplementation((url) => {
        if (url.includes('subjects/test.json?details=true&offset=')) {
            return Promise.resolve({ data: subjectsResponse });
        } else if (url.endsWith('subjects/test.json?details=true')) {
            return Promise.resolve({ data: subjectsResponse });
        } else if (url.endsWith('/works/OL138052W.json?details=true')) {
        return Promise.resolve({ data: keyResponse });
        } else if (url.endsWith('/editions.json')) {
            return Promise.resolve({ data: editionsResponse });
        } else if (url.endsWith('/authors/OL22098A.json')) {
            return Promise.resolve({ data: authorResponse });
        } else if (url.startsWith('https://uk.bookshop.org/search')) {
          return Promise.resolve({ data: aliceinWonderlandResponse });
        }
        return {};
    });

    // Act: call the new combined function to fetch and enrich
    await wrappedFetchAndEnrichBooks({ data: { userId } });
    // delay for Firestore to update
    await new Promise(resolve => setTimeout(resolve, 1000));
    // Assert: check that the book document was updated
    const query = await db.collection('users').doc(userId).collection('books').orderBy('createdAt', 'desc').limit(1).get();
    const bookDoc = query.docs[0];
    const data = bookDoc.data();
    const expectedResponse = require('./expectedResponse.json');
    expect(data.description).toBe(expectedResponse.description);
    expect(data.isbn_13[0]).toEqual(expectedResponse.isbn_13[0]);
    expect(data.cover_id[0]).toBe(expectedResponse.cover_id[0]);
    expect(data.languages[0].key).toEqual('/languages/eng');
    expect(data.bookshop_cover_url).toBe(expectedResponse.bookshop_cover_url);
    expect(data.key).toEqual(expectedResponse.key);});*/
});
