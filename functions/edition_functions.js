// Function to parse the publish_date and extract the year
function parseYear(publishDate) {
  if (!publishDate) return null;
  const match = publishDate.match(/\d{4}/);
  return match ? parseInt(match[0], 10) : null;
}

// Function to process editions and select the most recent one
function getMostRecentEdition(editions) {
  const editionsWithYear = editions
    .map(edition => ({
      ...edition,
      _year: parseYear(edition.publish_date),
    }))
    .filter(edition => edition._year)
    .sort((a, b) => b._year - a._year);

  return editionsWithYear[0] || null;
}

// Export the functions for use in other files
module.exports = {
  parseYear,
  getMostRecentEdition,
};