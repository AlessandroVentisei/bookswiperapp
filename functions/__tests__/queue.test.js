// Jest test for likeBook and fetchBooks Firebase Functions
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
const test = require('firebase-functions-test')({
  projectId: 'demo-test',
}, './serviceAccountKey.json');
const admin = require('firebase-admin');
const myFunctions = require('../index');
const axios = require('axios');
jest.mock('axios');

describe('Queue Functions', () => {
  let wrappedLikeBook, wrappedFetchBooks, wrappedEnrichQueue;
  let db;

  beforeAll(() => {
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
    const workKey = '/works/OL12345W';
    await db.collection('users').doc(userId).set({});
    await db.collection('users').doc(userId).collection('books').doc(bookId).set({
      workKey: workKey,
      title: 'Test Book',
    });

    // Mock OpenLibrary API responses
    axios.get.mockImplementation((url) => {
      if (url.endsWith('.json')) {
        return Promise.resolve({ data: {
          subjects: ['Fiction', 'Adventure'],
          description: { value: 'A test description.' },
        }});
      } else if (url.endsWith('/editions.json')) {
        return Promise.resolve({ data: {
          entries: [
            {
              isbn_13: ['1234567890123'],
              covers: [42],
              languages: [{ key: '/languages/eng' }],
              subtitle: 'A Test Subtitle',
              publish_date: '2020',
              publishers: ['Test Publisher'],
              subjects: ['Fiction'],
              pagination: '123p',
            }
          ]
        }});
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
    expect(data.subjects).toEqual(['Fiction', 'Adventure']);
    expect(data.description).toBe('A test description.');
    expect(data.isbn13).toEqual(['1234567890123']);
    expect(data.coverId).toBe(42);
    expect(data.language_keys).toEqual(['/languages/eng']);
    expect(data.subtitle).toBe('A Test Subtitle');
    expect(data.publishedDate).toBe('2020');
    expect(data.publisher).toEqual(['Test Publisher']);
    expect(data.subjects_edition).toEqual(['Fiction']);
    expect(data.pagination).toBe('123p');
  });
});
