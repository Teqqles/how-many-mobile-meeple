const http = require('http');
const url = require('url');

const PORT = 3000;

// Mock game data
const mockGames = {
  'testuser1': [
    {
      id: 174430,
      name: 'Gloomhaven',
      maxplayers: 4,
      minplayers: 1,
      maxplaytime: 120,
      image: 'https://cf.geekdo-images.com/sZYp_3BTDGjh2unaZfZmuA__original/img/pKft1d38Zr88VoM_vk5SbZjtQsk=/0x0/filters:format(jpeg)/pic2437871.jpg',
      stats: {
        average: 8.7,
        averageweight: 3.86
      }
    },
    {
      id: 167791,
      name: 'Terraforming Mars',
      maxplayers: 5,
      minplayers: 1,
      maxplaytime: 120,
      image: 'https://cf.geekdo-images.com/wg9oOLcsKvDesSUdZQ4rxw__original/img/FS1RE8Ue6nk1pNbPI3l-OSapQGc=/0x0/filters:format(jpeg)/pic3536616.jpg',
      stats: {
        average: 8.4,
        averageweight: 3.25
      }
    },
    {
      id: 120677,
      name: 'Terra Mystica',
      maxplayers: 5,
      minplayers: 2,
      maxplaytime: 150,
      image: 'https://cf.geekdo-images.com/bre12PlN4lHLHlh952hQxA__original/img/OsoO8BEgAV0EbiT93wWSIGWfIbY=/0x0/filters:format(jpeg)/pic5375624.jpg',
      stats: {
        average: 8.2,
        averageweight: 3.96
      }
    },
    {
      id: 173346,
      name: '7 Wonders Duel',
      maxplayers: 2,
      minplayers: 2,
      maxplaytime: 30,
      image: 'https://cf.geekdo-images.com/zdagMskTF7wJBPjX74XsRw__original/img/HTQ2lCadX539-98Mhc8ClBs7haU=/0x0/filters:format(jpeg)/pic2576399.jpg',
      stats: {
        average: 8.1,
        averageweight: 2.22
      }
    },
    {
      id: 68448,
      name: '7 Wonders',
      maxplayers: 7,
      minplayers: 2,
      maxplaytime: 30,
      image: 'https://cf.geekdo-images.com/35h9Za_JvMMMtx_92kT0Jg__original/img/wV52p4K46YPSDqwZDAyyAcx5jjI=/0x0/filters:format(jpeg)/pic7149798.jpg',
      stats: {
        average: 7.7,
        averageweight: 2.33
      }
    }
  ],
  'testuser2': [
    {
      id: 266192,
      name: 'Wingspan',
      maxplayers: 5,
      minplayers: 1,
      maxplaytime: 70,
      image: 'https://cf.geekdo-images.com/yLZJCVLlIx4c7eJEWUNJ7w__original/img/uIjeoKgHMcRtzRSR4MoUYl3nXxs=/0x0/filters:format(jpeg)/pic4458123.jpg',
      stats: {
        average: 8.0,
        averageweight: 2.44
      }
    },
    {
      id: 182028,
      name: 'Azul',
      maxplayers: 4,
      minplayers: 2,
      maxplaytime: 45,
      image: 'https://cf.geekdo-images.com/aPSHJO0d0XOpQR5X-wJonw__original/img/q4uWd2nLa6aOSXiTKJJQq-dUCIo=/0x0/filters:format(jpeg)/pic6973671.jpg',
      stats: {
        average: 7.8,
        averageweight: 1.78
      }
    },
    {
      id: 224517,
      name: 'Brass: Birmingham',
      maxplayers: 4,
      minplayers: 2,
      maxplaytime: 120,
      image: 'https://cf.geekdo-images.com/x3zxjr-Vw5iU4yDPg70Jgw__original/img/giNp6KyqjsRi8lbbZz5c8pBiUIw=/0x0/filters:format(jpeg)/pic3490053.jpg',
      stats: {
        average: 8.6,
        averageweight: 3.91
      }
    }
  ],
  'geeklist:12345': [
    {
      id: 291457,
      name: 'Cascadia',
      maxplayers: 4,
      minplayers: 1,
      maxplaytime: 45,
      image: 'https://cf.geekdo-images.com/MjeJZfulbsM1DSV3DrGJYA__original/img/xJNb7f0n3NzPdg8ioGG1xh7_X3w=/0x0/filters:format(jpeg)/pic5100691.jpg',
      stats: {
        average: 7.9,
        averageweight: 1.92
      }
    },
    {
      id: 169786,
      name: 'Scythe',
      maxplayers: 5,
      minplayers: 1,
      maxplaytime: 115,
      image: 'https://cf.geekdo-images.com/7k_nOxpO9OGIjhLq2BUZdA__original/img/XO9E6wvmGlZiyjNZRqMSSYUF8LI=/0x0/filters:format(jpeg)/pic3163924.jpg',
      stats: {
        average: 8.0,
        averageweight: 3.38
      }
    }
  ]
};

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  console.log(`[${new Date().toISOString()}] ${req.method} ${path}`);

  // Health check
  if (path === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', message: 'Mock API is running' }));
    return;
  }

  // Helper function to filter games based on headers
  const filterGames = (games, headers) => {
    let filtered = [...games];

    // Filter by player count
    const playerCount = headers['bgg-filter-player-count'];
    if (playerCount) {
      const count = parseInt(playerCount);
      filtered = filtered.filter(g => g.minplayers <= count && g.maxplayers >= count);
    }

    // Filter by min duration
    const minDuration = headers['bgg-filter-min-duration'];
    if (minDuration) {
      const min = parseInt(minDuration);
      filtered = filtered.filter(g => g.maxplaytime >= min);
    }

    // Filter by max duration
    const maxDuration = headers['bgg-filter-max-duration'];
    if (maxDuration) {
      const max = parseInt(maxDuration);
      filtered = filtered.filter(g => g.maxplaytime <= max);
    }

    // Filter by max complexity
    const maxComplexity = headers['bgg-filter-max-complexity'];
    if (maxComplexity) {
      const complexity = parseFloat(maxComplexity);
      filtered = filtered.filter(g => g.stats.averageweight <= complexity);
    }

    // Filter by min rating
    const minRating = headers['bgg-filter-min-rating'];
    if (minRating) {
      const rating = parseFloat(minRating);
      filtered = filtered.filter(g => g.stats.average >= rating);
    }

    return filtered;
  };

  // Handle collection endpoint: /collection/username
  const collectionMatch = path.match(/^\/collection\/(.+)$/);
  if (collectionMatch) {
    const username = decodeURIComponent(collectionMatch[1]);
    let games = mockGames[username] || mockGames['testuser1'];

    // Apply filters
    games = filterGames(games, req.headers);

    console.log(`  → Returning ${games.length} games after filtering`);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(games));
    return;
  }

  // Handle geeklist endpoint: /geeklist/id
  const geeklistMatch = path.match(/^\/geeklist\/(.+)$/);
  if (geeklistMatch) {
    const geeklistId = decodeURIComponent(geeklistMatch[1]);
    let games = mockGames[`geeklist:${geeklistId}`] || mockGames['geeklist:12345'];

    // Apply filters
    games = filterGames(games, req.headers);

    console.log(`  → Returning ${games.length} games after filtering`);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(games));
    return;
  }

  // Handle CORS proxy for images
  const corsProxyMatch = path.match(/^\/cors-proxy\/(.+)$/);
  if (corsProxyMatch) {
    // For simplicity, just return a 200 OK - the app will handle the image display
    res.writeHead(200, { 'Content-Type': 'image/jpeg' });
    res.end();
    return;
  }

  // 404 for unknown routes
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    error: 'Not Found',
    path: path,
    hint: 'Try /collection/testuser1 or /geeklist/12345'
  }));
});

server.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════╗
║   Mock API Server Running                     ║
╚═══════════════════════════════════════════════╝

  🚀 Server:    http://localhost:${PORT}
  ✅ Health:    http://localhost:${PORT}/health

  📋 Available Endpoints:
     GET /collection/:username
     GET /geeklist/:id
     GET /cors-proxy/:base64url

  📦 Mock Users:
     • testuser1  (5 games)
     • testuser2  (3 games)

  📦 Mock Geeklists:
     • 12345      (2 games)

  Press Ctrl+C to stop
`);
});
