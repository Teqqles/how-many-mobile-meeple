# Mock API Server for How Many Meeple

A lightweight Node.js mock server that mimics the Board Game Geek proxy API for local development and testing.

## 🚀 Quick Start

### Prerequisites
- Node.js installed (no additional packages needed - uses built-in modules only!)

### Running the Server

```bash
cd mock-api
npm start
```

Or directly:
```bash
node server.js
```

The server will start on `http://localhost:3000`

## 📋 Available Endpoints

### 1. Health Check
```
GET http://localhost:3000/health
```
Returns: `{"status": "ok", "message": "Mock API is running"}`

### 2. Collection Endpoint
```
GET http://localhost:3000/collection/:username
```
Returns an array of games for the specified user.

**Mock Users:**
- `testuser1` - 5 popular board games
- `testuser2` - 3 board games
- Any other username returns testuser1's collection

**Example:**
```bash
curl http://localhost:3000/collection/testuser1
```

### 3. Geeklist Endpoint
```
GET http://localhost:3000/geeklist/:id
```
Returns an array of games for the specified geeklist.

**Mock Geeklists:**
- `12345` - 2 board games
- Any other ID returns the default geeklist

**Example:**
```bash
curl http://localhost:3000/geeklist/12345
```

### 4. CORS Proxy (for images)
```
GET http://localhost:3000/cors-proxy/:base64url
```
Returns a 200 OK for image proxy requests (simplified for local testing).

## 📦 Response Format

Each endpoint returns an array of game objects:

```json
[
  {
    "id": 174430,
    "name": "Gloomhaven",
    "maxplayers": 4,
    "minplayers": 1,
    "maxplaytime": 120,
    "image": "https://example.com/image.jpg",
    "stats": {
      "average": 8.7,
      "averageweight": 3.86
    }
  }
]
```

## 🔧 Configure Flutter App to Use Mock API

Update `lib/app_common.dart`:

```dart
static const String boardGameGeekProxyUrl =
    "http://localhost:3000";  // For local testing
    // "https://api.howmanymeeple.com";  // Production
```

## 🎮 Testing with the App

1. Start the mock server:
   ```bash
   cd mock-api
   npm start
   ```

2. Update the API URL in the Flutter app (see above)

3. Run the Flutter app:
   ```bash
   flutter run -d chrome
   ```

4. In the app, enter one of these:
   - Username: `testuser1` or `testuser2` (select "collection" type)
   - Geeklist ID: `12345` (select "geeklist" type)

## 📝 Mock Data Included

### testuser1 (5 games)
- Gloomhaven (8.7 rating, heavy)
- Terraforming Mars (8.4 rating, medium-heavy)
- Terra Mystica (8.2 rating, heavy)
- 7 Wonders Duel (8.1 rating, medium)
- 7 Wonders (7.7 rating, medium)

### testuser2 (3 games)
- Wingspan (8.0 rating, medium)
- Azul (7.8 rating, light)
- Brass: Birmingham (8.6 rating, heavy)

### geeklist:12345 (2 games)
- Cascadia (7.9 rating, light)
- Scythe (8.0 rating, medium-heavy)

## 🛠️ Customizing Mock Data

Edit `server.js` and modify the `mockGames` object to add/remove games or users:

```javascript
const mockGames = {
  'yourusername': [
    {
      id: 123,
      name: 'Your Game',
      // ... more properties
    }
  ]
};
```

## ✨ Features

- ✅ Zero dependencies (uses only Node.js built-in modules)
- ✅ CORS enabled for local development
- ✅ Request logging with timestamps
- ✅ Realistic board game data
- ✅ Simple and easy to modify
- ✅ Fast startup (~50ms)

## 🐛 Troubleshooting

**Port already in use?**
Change the `PORT` constant at the top of `server.js`:
```javascript
const PORT = 3001; // or any available port
```

**Flutter app can't connect?**
Make sure:
1. The mock server is running
2. The URL in `app_common.dart` matches the server port
3. You're running the Flutter web app (mobile apps need special network permissions)

## 📄 License

MIT
