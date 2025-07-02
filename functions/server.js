const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

// Load API key from keys.json
const keysPath = path.join(__dirname, 'keys.json');
const { googleApiKey } = JSON.parse(fs.readFileSync(keysPath, 'utf8'));
const cx = 'd4c9acc4363294148';

app.post('/cover', async (req, res) => {
  const { title, author } = req.body;
  if (!title) return res.status(400).json({ error: 'Missing title' });

  const query = `${title} ${author || ''} book cover`.trim();
  const url = `https://www.googleapis.com/customsearch/v1?key=${googleApiKey}&cx=${cx}&q=${encodeURIComponent(query)}&searchType=image`;
  console.log('Google Images API search for:', query);

  try {
    const response = await axios.get(url);
    const items = response.data.items;
    if (items && items.length > 0) {
      const firstImageUrl = items[0].link;
      res.json({ coverUrl: firstImageUrl });
    } else {
      res.status(404).json({ error: 'Cover not found' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`Listening on port ${PORT}`));
