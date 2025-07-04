const axios = require('axios');

// Function to parse the publish_date and extract the year
const logger = require("firebase-functions/logger");
function parseYear(publishDate) {
  if (!publishDate) return null;
  const match = publishDate.match(/\d{4}/);
  return match ? parseInt(match[0], 10) : null;
}

// Function to process editions and select the most recent one
function getMostRecentEdition(editions) {
  // filter out editions that aren't english, don't have a cover or don't have an ISBN-13
  editions = editions.filter(edition => {
    return edition.isbn_13?.length > 0 && edition.languages?.some(lang => lang.key === '/languages/eng') && edition.covers?.length > 0;
  });
  // Helper to count how many important fields are present
  function fieldScore(edition) {
    let score = 0;
    if (edition.covers && edition.covers.length > 0) score++;
    if (edition.subtitle) score++;
    if (edition.publish_date) score++;
    if (edition.publishers && edition.publishers.length > 0) score++;
    if (edition.subjects && edition.subjects.length > 0) score++;
    if (edition.number_of_pages) score++;
    return score;
  }

  // Map editions to include year and field score
  const editionsWithMeta = editions.map(edition => ({
    ...edition,
    _year: parseYear(edition.publish_date),
    _score: fieldScore(edition),
  }));

  // Prefer editions with a year, sort by year desc, then by field score desc
  const withYear = editionsWithMeta.filter(e => e._year).sort((a, b) => {
    if (b._year !== a._year) return b._year - a._year;
    return b._score - a._score;
  });
  if (withYear.length > 0) return withYear[0];

  // If no editions have a year, pick the one with the most fields present
  const byScore = editionsWithMeta.sort((a, b) => b._score - a._score);
  return byScore[0] || null;
}

// Helper to fetch cover image from Cloud Run service
async function fetchBookshopCover(title, authorName) {
    try {
        const response = await axios.post(
            'https://bookshop-cover-scraper-131230945810.europe-west2.run.app/cover',
            { title, author: authorName },
            { timeout: 5000 }
        );
        if (response.data && response.data.coverUrl) {
            return response.data.coverUrl;
        }
        return null;
    } catch (err) {
        logger.error('Cloud Run cover fetch failed', err);
        return null;
    }
}

// Export the functions for use in other files
module.exports = {
  parseYear,
  getMostRecentEdition,
  fetchBookshopCover
};