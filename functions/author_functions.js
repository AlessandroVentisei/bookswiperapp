import axios from 'axios';
import fs from 'fs';
import path from 'path';
import { googleAI } from '@genkit-ai/googleai';
import { genkit } from 'genkit';

// ESM-compatible __dirname
const __dirname = path.dirname(new URL(import.meta.url).pathname);
const keysPath = path.join(__dirname, 'keys.json');
const { googleGenkit } = JSON.parse(fs.readFileSync(keysPath, 'utf8'));
process.env.GOOGLE_API_KEY = googleGenkit;

// Initialize Genkit with GoogleAI plugin
const ai = genkit({
  plugins: [googleAI()],
  model: googleAI.model('gemini-2.5-flash'),
});

export async function enrichAuthorsWithOpenLibrary(suggestions) {
  const enriched = [];
  for (const suggestion of suggestions) {
    const name = suggestion.name;
    try {
      const url = `https://openlibrary.org/search/authors.json?q=${encodeURIComponent(name)}`;
      const resp = await axios.get(url);
      if (resp.data && resp.data.docs && resp.data.docs.length > 0) {
        const authorDoc = resp.data.docs[0];
        enriched.push({
          name: authorDoc.name,
          key: "/authors/"+authorDoc.key,
          top_work: authorDoc.top_work,
          work_count: authorDoc.work_count,
          reason: suggestion.reason || null,
        });
      }
    } catch (e) {
      // On error, add the suggestion as-is
      console.error(`Error fetching author ${name}:`, e.message);
    }
  }
  return enriched;
}

/**
 * Given a list of liked authors and subject keywords, use Gemini to suggest additional authors.
 * @param {Array<{name: string, key?: string}>} likedAuthors
 * @param {Array<string>} subjectKeywords
 * @returns {Promise<Array<{name: string, reason?: string}>>}
 */

function cleanGeminiJsonResponse(text) {
  // Remove code block markers and trim whitespace
  return text.replace(/```json|```/gi, '').trim();
}

export async function getGeminiAuthorSuggestions(likedAuthors, subjectKeywords) {
  const authorNames = likedAuthors.map(a => a.name).join(', ');
  const prompt = `A user has liked authors: ${authorNames}. Their favourite book subjects are: ${subjectKeywords.join(', ')}. Suggest 5 more authors they might enjoy, as a JSON array of objects with 'name' and (if possible) 'reason'.`;
  let suggestions = [];
  try {
    const response = await ai.generate({
      model: googleAI.model('gemini-2.5-flash'),
      prompt,
    });
    const cleanedText = cleanGeminiJsonResponse(response.text);
    suggestions = JSON.parse(cleanedText);
  } catch (e) {
    // If parsing fails, return empty array
    console.error('Gemini suggestion error:', e);
  }
  return suggestions;
}