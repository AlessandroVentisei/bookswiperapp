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
  let wrappedLikeBook, wrappedFetchBooks, wrappedEnrichQueue;
  let db;

  beforeAll(async () => {
    db = admin.firestore();
    wrappedLikeBook = test.wrap(myFunctions.likeBook);
    wrappedFetchBooks = test.wrap(myFunctions.fetchBooks);
    wrappedEnrichQueue = test.wrap(myFunctions.enrichQueue);
});

  afterAll(async () => {
    test.cleanup();
    // Properly clean up the Firebase Admin app to close open handles
    await Promise.all(admin.apps.map(app => app.delete()));
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
    await db.collection('users').doc(userId).set({"username": "testuser"});
    await db.collection('users').doc(userId).collection('books').doc(bookId).set({
      key: workKey,
      title: 'Test Book',
    });
    // Mock the OpenLibrary API response for the work key
    const keyResponse = require('./keyResponse.json');
    const editionsResponse = require('./editionsResponse.json');
    // Mock OpenLibrary API responses
    axios.get.mockImplementation((url) => {
      if (url.endsWith('/works/OL66554W.json')) {
        // Use require to synchronously load the JSON file for Jest
        return Promise.resolve({ data: keyResponse });
      } else if (url.endsWith('/editions.json')) {
        return Promise.resolve({ data: editionsResponse });
      }
      return Promise.resolve({ data: {} });
    });

    // Act: simulate Firestore document creation event
    await wrappedEnrichQueue({
      params: { userId, bookId },
    });
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

  it('should fetch new books and add them to the user queue', async () => {
    const userId = 'fetchuser';
    const queueRef = db.collection('users').doc(userId).collection('books');

    // Setup: user document with subject keywords and a small queue
    await db.collection('users').doc(userId).set({
      subjectKeywords: ['science'],
      fetchedSubjects: [],
      currentIndex: 0,
      isUpdating: false,
    });
    await queueRef.add({ key: '/works/OLD1', title: 'Old Book' });
    const beforeSnapshot = await queueRef.get();

    // Mock OpenLibrary API responses used in fetchBooks
    axios.get.mockImplementation((url) => {
      if (url.includes('/subjects/science.json')) {
        return Promise.resolve({ data: { subjects: [{ key: 'subjects/physics' }] } });
      } else if (url.includes('subjects/physics.json')) {
        return Promise.resolve({
          data: {
            works: [
              {
                title: 'Physics 101',
                authors: [{ name: 'Albert', key: '/authors/A1' }],
                first_publish_year: 2000,
                cover_edition_key: null,
                cover_id: null,
                key: '/works/WNEW',
                subject: ['physics'],
                description: { value: 'desc' },
              },
            ],
          },
        });
      }
      return Promise.resolve({ data: {} });
    });

    await wrappedFetchBooks({ userId });

    const afterSnapshot = await queueRef.get();
    expect(afterSnapshot.size).toBeGreaterThan(beforeSnapshot.size);

    // Clean up created data
    await Promise.all(afterSnapshot.docs.map((doc) => doc.ref.delete()));
    await db.collection('users').doc(userId).delete();
  });
});
