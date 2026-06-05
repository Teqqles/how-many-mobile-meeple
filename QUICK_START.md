# Quick Start Guide

## 🚀 Run Locally with Mock API (3 steps)

### 1. Start Mock Server
```bash
cd mock-api && node server.js
```
✅ Server running at http://localhost:3000

### 2. Configure App
```bash
cp web/config.json web/config.local.json
```
✅ App will use local API automatically

### 3. Run Flutter
```bash
flutter run -d chrome
```
✅ App running with mock data!

## 📝 Test Accounts

| Type | Enter | Gets |
|------|-------|------|
| Collection | `testuser1` | 5 games |
| Collection | `testuser2` | 3 games |
| Geeklist | `12345` | 2 games |

## 🔄 Switch to Production

```bash
rm web/config.local.json
```
Done! App uses production API now.

## 📖 More Info

- **Full testing guide**: [TESTING.md](TESTING.md)
- **Config details**: [web/CONFIG.md](web/CONFIG.md)
- **Mock API docs**: [mock-api/README.md](mock-api/README.md)

---

### Mobile Development?

```bash
# Find your computer's IP
ipconfig  # Windows
ifconfig  # Mac/Linux

# Run with that IP
flutter run --dart-define=API_URL=http://192.168.1.100:3000
```

### Production Build?

```bash
flutter build web --release
# Deploys with config.json automatically
```

That's it! 🎉
