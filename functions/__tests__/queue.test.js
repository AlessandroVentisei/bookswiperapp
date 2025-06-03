// Jest test for likeBook and fetchBooks Firebase Functions
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
const test = require('firebase-functions-test')({
  projectId: 'matchbook-b610d',
}, './serviceAccountKey.json');
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

  afterAll(() => {
    test.cleanup();
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
      workKey: workKey,
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
    // Wait for the Firestore document to be updated
    // await new Promise(resolve => setTimeout(resolve, 3000));
    // Assert: check that the book document was updated
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    const data = bookDoc.data();
    expect(data.subjects).toEqual(keyResponse.subjects);
    expect(data.description).toBe(keyResponse.description);
    expect(data.isbn13[0]).toEqual("9781648337093");
    expect(data.coverId).toBe(14665299);
    expect(data.languages).toEqual(['/languages/eng']);
    expect(data.subtitle).toBe('');
    expect(data.publishedDate).toBe('2024');
    expect(data.publisher).toEqual(["Page Publications"]);
    expect(data.subjects_edition).toEqual(['Fiction, general']);
    expect(data.number_of_pages).toBe('');
  });
});
