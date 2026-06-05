# Testing How Many Meeple Locally

This guide explains how to run the app locally using the mock API server for testing without hitting the real Board Game Geek API.

## 🚀 Quick Start

### 1. Start the Mock API Server

**Windows:**
```cmd
cd mock-api
start.bat
```

**Mac/Linux:**
```bash
cd mock-api
chmod +x start.sh
./start.sh
```

**Or directly with Node:**
```bash
cd mock-api
node server.js
```

You should see:
```
╔═══════════════════════════════════════════════╗
║   Mock API Server Running                     ║
╚═══════════════════════════════════════════════╝

🚀 Server:    http://localhost:3000
✅ Health:    http://localhost:3000/health
```

### 2. Configure Flutter App for Mock API

**For Web (Recommended):**

Create `web/config.local.json`:
```bash
cp web/config.json web/config.local.json
```

The file should contain:
```json
{
  "apiUrl": "http://localhost:3000",
  "environment": "development"
}
```

That's it! The app automatically uses `config.local.json` if it exists.

**For Mobile:**

Use the `--dart-define` flag:
```bash
flutter run --dart-define=API_URL=http://192.168.1.100:3000
```
(Replace with your computer's IP address)

### 3. Run the Flutter App

**Web (Recommended for testing):**
```bash
flutter run -d chrome
```

**All platforms:**
```bash
flutter run
```

### 4. Test with Mock Data

In the app, try these test accounts:

**Collections (select person icon):**
- Enter: `testuser1` → Get 5 board games
- Enter: `testuser2` → Get 3 board games

**Geeklists (select list icon):**
- Enter: `12345` → Get 2 board games

## 📦 Mock Data Available

### testuser1
- Gloomhaven (Heavy, 1-4 players, 120 min)
- Terraforming Mars (Medium-Heavy, 1-5 players, 120 min)
- Terra Mystica (Heavy, 2-5 players, 150 min)
- 7 Wonders Duel (Medium, 2 players, 30 min)
- 7 Wonders (Medium, 2-7 players, 30 min)

### testuser2
- Wingspan (Medium, 1-5 players, 70 min)
- Azul (Light, 2-4 players, 45 min)
- Brass: Birmingham (Heavy, 2-4 players, 120 min)

### geeklist:12345
- Cascadia (Light, 1-4 players, 45 min)
- Scythe (Medium-Heavy, 1-5 players, 115 min)

## 🧪 Testing Filters

Once you load games, test these filters:

1. **Player Count**: Try 2, 4, or 5 players
2. **Play Time**: Try 30-60 min, 60-120 min
3. **Difficulty**: Try 2.0 (light), 3.0 (medium), 4.0 (heavy)
4. **Min Rating**: Try 7.5, 8.0, 8.5
5. **Mechanics**: Try various game mechanics

## 🔄 Switch Back to Production

When done testing, simply **delete or rename** `web/config.local.json`:

```bash
# Option 1: Delete it
rm web/config.local.json

# Option 2: Rename it
mv web/config.local.json web/config.local.json.bak
```

The app will automatically fall back to `config.json` (production).

**No code changes needed!** 🎉

## 🐛 Troubleshooting

### Mock server won't start
- **Port in use**: Change `PORT` in `mock-api/server.js` to 3001 or another port
- **Node not found**: Install Node.js from https://nodejs.org

### App can't connect to mock server
- Check the server is running (`curl http://localhost:3000/health`)
- Verify `web/config.local.json` exists and has correct API URL
- Check browser dev tools (F12) → Network tab for config file loading
- On mobile, you may need to use your computer's IP instead of `localhost`

### No games showing
- Open browser dev tools (F12) to see network errors
- Check the mock server console for incoming requests
- Verify you typed the username correctly (`testuser1`, `testuser2`, or `12345`)

## 📝 Adding Your Own Mock Data

Edit `mock-api/server.js` and add to the `mockGames` object:

```javascript
const mockGames = {
  'myusername': [
    {
      id: 999999,
      name: 'My Custom Game',
      maxplayers: 4,
      minplayers: 2,
      maxplaytime: 90,
      image: 'https://example.com/image.jpg',
      stats: {
        average: 7.5,
        averageweight: 2.5
      }
    }
  ],
  // ... existing mock data
};
```

Restart the mock server and use `myusername` in the app.

## ✅ What Gets Tested

With the mock API, you can test:
- ✅ Loading collections and geeklists
- ✅ All filtering features
- ✅ Sorting games
- ✅ Random game selection
- ✅ Game list display
- ✅ Save/load preferences
- ✅ UI responsiveness

Without needing:
- ❌ Real Board Game Geek accounts
- ❌ Internet connection
- ❌ Rate limiting concerns
- ❌ Slow API responses

## 🎯 Best Practices

1. **Always test locally first** before deploying changes
2. **Keep mock data realistic** (valid ratings, play times, etc.)
3. **Test edge cases** (0 games, max filters, etc.)
4. **Don't commit `config.local.json`** (it's already gitignored)
5. **Document any new test accounts** you add to the mock server
6. **Use `config.local.json` for web** and `--dart-define` for mobile

Happy testing! 🎲
