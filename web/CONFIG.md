# Web Configuration Files

The app uses JSON configuration files to set the API URL for different environments.

## Files

### `config.json` (Production)
- **Purpose**: Production configuration for deployed app
- **Committed**: ✅ Yes (committed to repository)
- **API URL**: `https://api.howmanymeeple.com`
- **Used**: When deployed to S3, Netlify, etc.

### `config.local.json` (Development)
- **Purpose**: Local development configuration
- **Committed**: ❌ No (git ignored)
- **API URL**: `http://localhost:3000`
- **Used**: When running `flutter run -d chrome` locally
- **Priority**: Loaded first (if exists), falls back to config.json

## How It Works

1. App starts and calls `AppConfig.initialize()`
2. On web platform:
   - Tries to load `/config.local.json` first
   - If not found, loads `/config.json`
   - If neither found, uses hardcoded default
3. API URL is cached and used throughout the app

## Configuration Format

```json
{
  "apiUrl": "http://localhost:3000",
  "environment": "development"
}
```

**Fields:**
- `apiUrl` (required): The base URL for API calls
- `environment` (optional): Environment name for logging

## Local Development Setup

1. Copy the production config:
   ```bash
   cp web/config.json web/config.local.json
   ```

2. Edit `web/config.local.json`:
   ```json
   {
     "apiUrl": "http://localhost:3000",
     "environment": "development"
   }
   ```

3. Start the mock API server:
   ```bash
   cd mock-api
   node server.js
   ```

4. Run Flutter web:
   ```bash
   flutter run -d chrome
   ```

The app will automatically use `config.local.json` and connect to your local mock server!

## Production Deployment

For production deployment, **only `config.json` should be deployed**:

### AWS S3 Deployment
```bash
# Build for production
flutter build web --release

# Deploy to S3 (config.json is included in build/web)
aws s3 sync build/web s3://your-bucket-name/
```

### Manual Deployment
1. Build the app: `flutter build web --release`
2. The `build/web` folder contains everything needed
3. `config.json` is automatically copied during build
4. Upload `build/web/*` to your hosting provider

### Custom Production API
To deploy with a different API URL (staging, etc.):

1. Edit `web/config.json` before building:
   ```json
   {
     "apiUrl": "https://api.staging.howmanymeeple.com",
     "environment": "staging"
   }
   ```

2. Build and deploy as normal

## Mobile Apps

Mobile apps don't use these JSON files. Instead, use build-time configuration:

```bash
# iOS/Android with custom API
flutter run --dart-define=API_URL=http://192.168.1.100:3000

# Production build
flutter build apk --release
```

## Troubleshooting

### App still uses production API locally
- Check `config.local.json` exists in `web/` folder
- Verify the file is valid JSON
- Check browser dev tools Network tab for 404 errors
- Clear browser cache and reload

### Config file not found in production
- Ensure `config.json` is in `web/` folder before building
- Check that `build/web/config.json` exists after building
- Verify your hosting serves the file (test: `https://yourdomain.com/config.json`)

### CORS errors loading config
- Config files are served from the same origin, so CORS shouldn't be an issue
- If you see CORS errors, check your hosting configuration

## Security Notes

- ⚠️ Config files are **publicly accessible** (they're served to the browser)
- ❌ **Never** put API keys, secrets, or tokens in these files
- ✅ Only put **public** configuration like API base URLs
- ✅ Use these for **non-sensitive** environment configuration only

## Summary

| File | Committed | Used When | Purpose |
|------|-----------|-----------|---------|
| `config.json` | ✅ Yes | Production | Deployed configuration |
| `config.local.json` | ❌ No | Local dev | Override for local testing |

Simple pattern: 
- **Developers**: Create `config.local.json` for local work
- **Production**: Only `config.json` gets deployed
- **No code changes needed** to switch environments!
