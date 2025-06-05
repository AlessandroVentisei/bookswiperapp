// Jest test for likeBook and fetchBooks Firebase Functions
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
const test = require('firebase-functions-test')({
  projectId: 'matchbook-b610d',
}, "./serviceAccountKey.json");
const admin = require('firebase-admin');
const myFunctions = require('../index');
const axios = require('axios');
jest.mock('axios');

describe('Queue Functions', () => {
  let wrappedLikeBook, wrappedFetchAndEnrichBooks;
  let db;

  beforeAll(async () => {
    db = admin.firestore();
    wrappedLikeBook = test.wrap(myFunctions.likeBook);
    wrappedFetchAndEnrichBooks = test.wrap(myFunctions.fetchAndEnrichBooks);
});

  afterAll(async () => {
    // test.cleanup();
    // Properly clean up the Firebase Admin app to close open handles
    // await Promise.all(admin.apps.map(app => app.delete()));
    jest.restoreAllMocks();
  });

  it('should return error if user param is missing in likeBook', async () => {
    await expect(wrappedLikeBook({ book: 'book1' })).rejects.toThrow();
  });

  it('should return error if book param is missing in likeBook', async () => {
    await expect(wrappedLikeBook({ user: 'user1' })).rejects.toThrow();
  });

  it('should enrich a book document with OpenLibrary data', async () => {
    // Arrange: create user and book in Firestore
    const userId = 'testuser';
    const bookId = 'testbook';
    const workKey = '/works/OL66554W';
    await db.collection('users').doc(userId).set({"username": "testuser", subjectKeywords: ["test"], fetchedSubjects: [], currentIndex: 0, isUpdating: false });
    // Mock the OpenLibrary API response for the work key
    const keyResponse = require('./keyResponse.json');
    const editionsResponse = require('./editionsResponse.json');
    const subjectsResponse = require('./subjectResponse.json');
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
        }
        return Promise.resolve({ data: {} });
    });

    // Act: call the new combined function to fetch and enrich
    await wrappedFetchAndEnrichBooks({ data: { userId } });

    // Assert: check that the book document was updated
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    const data = bookDoc.data();
    expect(data.subjects).toEqual(keyResponse.subjects);
    expect(data.description).toBe(keyResponse.description);
    expect(data.isbn_13[0]).toEqual('9781648337093');
    expect(data.covers[0]).toBe(14665299);
    expect(data.languages[0].key).toEqual('/languages/eng');
    expect(data.subtitle).toBe('');
    expect(data.publish_date).toBe('2024');
    expect(data.publishers).toEqual(['Page Publications']);
  });
});
