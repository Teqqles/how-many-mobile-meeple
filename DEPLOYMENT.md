# Deployment Guide

## 📦 Web Deployment (S3, Netlify, etc.)

### Prerequisites
- Flutter installed
- `web/config.json` configured with production API URL

### Build for Production

```bash
# Clean build
flutter clean
flutter pub get

# Build web release
flutter build web --release
```

Output: `build/web/` directory contains everything you need.

---

## 🌐 AWS S3 + CloudFront

### 1. Build the App
```bash
flutter build web --release
```

### 2. Deploy to S3
```bash
# Using AWS CLI
aws s3 sync build/web/ s3://your-bucket-name/ --delete

# Set proper MIME types
aws s3 cp s3://your-bucket-name/ s3://your-bucket-name/ \
  --recursive \
  --exclude "*" \
  --include "*.json" \
  --content-type "application/json" \
  --metadata-directive REPLACE
```

### 3. Configure S3 Bucket
- Enable Static Website Hosting
- Set Index Document: `index.html`
- Set Error Document: `index.html` (for SPA routing)
- Make bucket public or use CloudFront

### 4. CloudFront Distribution (Optional)
- Create distribution pointing to S3 bucket
- Set Default Root Object: `index.html`
- Add Custom Error Response: 404 → /index.html (200)
- Enable HTTPS

---

## 🚀 Netlify

### Option 1: Drag & Drop
1. Build: `flutter build web --release`
2. Go to https://app.netlify.com/drop
3. Drag `build/web` folder
4. Done! ✨

### Option 2: Git Deploy
1. Connect your repository
2. Set build command: `flutter build web --release`
3. Set publish directory: `build/web`
4. Deploy!

### Netlify Configuration
Create `netlify.toml`:
```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

## 🔧 Vercel

### Deploy with Vercel CLI
```bash
# Install Vercel CLI
npm i -g vercel

# Build
flutter build web --release

# Deploy
cd build/web
vercel --prod
```

### Vercel Configuration
Create `vercel.json`:
```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "routes": [
    { "handle": "filesystem" },
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
```

---

## 🐳 Docker

Create `Dockerfile`:
```dockerfile
# Build stage
FROM cirrusci/flutter:stable AS build

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

# Serve stage
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

Create `nginx.conf`:
```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(json)$ {
        add_header Content-Type application/json;
    }
}
```

Build and run:
```bash
docker build -t meeple-app .
docker run -p 8080:80 meeple-app
```

---

## 🔐 Environment Configuration

### Production API (default)
`web/config.json`:
```json
{
  "apiUrl": "https://api.howmanymeeple.com",
  "environment": "production"
}
```

### Staging Environment
`web/config.json`:
```json
{
  "apiUrl": "https://api.staging.howmanymeeple.com",
  "environment": "staging"
}
```

### Custom Environment
1. Edit `web/config.json` before building
2. Build: `flutter build web --release`
3. Deploy the `build/web` folder

**Important**: `config.json` is baked into the build. To change API URL:
- Rebuild the app, OR
- Manually edit `build/web/config.json` before deploying

---

## ✅ Post-Deployment Checklist

- [ ] App loads at your domain
- [ ] `/config.json` is accessible (check browser dev tools)
- [ ] API calls work (test loading games)
- [ ] All routes work (refresh on any page)
- [ ] Images load properly
- [ ] HTTPS is enabled (for production)
- [ ] CORS is configured correctly on API server
- [ ] Browser console has no errors

---

## 🐛 Troubleshooting

### App shows blank page
- Check browser console for errors
- Verify `index.html` is being served
- Check that all assets loaded (Network tab)

### API calls fail
- Verify `config.json` is accessible: `https://yourdomain.com/config.json`
- Check CORS headers on API server
- Verify API URL in config.json is correct

### Routes don't work (404 on refresh)
- Configure your host to serve `index.html` for all routes
- S3: Set error document to `index.html`
- Netlify: Add redirect rule (see above)
- Nginx: Use `try_files` directive (see above)

### Images don't load
- Check image URLs in browser dev tools
- Verify CORS on image hosting
- Check network tab for 404s or CORS errors

---

## 📊 Performance Tips

### Optimize Build
```bash
# Enable tree-shaking and minification (default in --release)
flutter build web --release

# Build with specific renderer (auto, canvaskit, or html)
flutter build web --release --web-renderer canvaskit
```

### CDN Configuration
- Enable compression (gzip/brotli)
- Set cache headers:
  - `index.html`: no-cache
  - `config.json`: no-cache
  - Other assets: long cache (immutable)

### S3 Cache Headers Example
```bash
# No cache for HTML and config
aws s3 cp build/web/index.html s3://bucket/ \
  --cache-control "no-cache, no-store, must-revalidate"

aws s3 cp build/web/config.json s3://bucket/ \
  --cache-control "no-cache, no-store, must-revalidate"

# Long cache for assets
aws s3 cp build/web/assets/ s3://bucket/assets/ \
  --recursive \
  --cache-control "public, max-age=31536000, immutable"
```

---

## 🔄 Update Deployment

```bash
# 1. Update code
git pull origin main

# 2. Build
flutter build web --release

# 3. Deploy (example for S3)
aws s3 sync build/web/ s3://your-bucket-name/ --delete

# 4. Invalidate CDN cache (if using CloudFront)
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"
```

---

## 📱 Mobile App Deployment

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Build iOS
flutter build ios --release

# Then use Xcode to archive and upload to App Store
```

### Mobile with Custom API
```bash
flutter build apk --release --dart-define=API_URL=https://api.custom.com
```

---

## 📖 More Resources

- **Testing locally**: [TESTING.md](TESTING.md)
- **Config details**: [web/CONFIG.md](web/CONFIG.md)
- **Quick start**: [QUICK_START.md](QUICK_START.md)
- **Flutter deployment docs**: https://docs.flutter.dev/deployment/web

---

**Ready to deploy!** 🚀
