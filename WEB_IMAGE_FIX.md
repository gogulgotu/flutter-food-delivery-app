# Web Image Loading Fix Guide

## Current Issue
Images from Google Cloud Storage are not displaying in Flutter web app, even though:
- ✅ URLs work when opened directly in browser
- ✅ URLs are correctly extracted from API
- ✅ App is using `Image.network` for web platform

## Root Cause
This is likely a **CORS (Cross-Origin Resource Sharing)** issue. Flutter web makes requests differently than direct browser access.

## Solution Steps

### Step 1: Check Browser Console
1. Open your Flutter web app in Chrome
2. Press **F12** to open DevTools
3. Go to **Console** tab
4. Look for errors like:
   - `CORS policy: No 'Access-Control-Allow-Origin' header`
   - `Failed to load resource: net::ERR_FAILED`
   - `Image load error`

### Step 2: Configure CORS on Google Cloud Storage

The bucket needs to allow cross-origin requests from your Flutter web app.

#### Option A: Using Google Cloud Console (Recommended)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **Cloud Storage** → **Buckets**
3. Click on your bucket: `inspired-micron-474510-a3-public-media`
4. Click on **Permissions** tab
5. Click **Edit CORS configuration**
6. Add this JSON configuration:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": [
      "Content-Type",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Methods",
      "Access-Control-Allow-Headers"
    ],
    "maxAgeSeconds": 3600
  }
]
```

7. Click **Save**

#### Option B: Using gsutil Command Line

```bash
# Create a CORS configuration file (cors.json)
cat > cors.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": [
      "Content-Type",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Methods",
      "Access-Control-Allow-Headers"
    ],
    "maxAgeSeconds": 3600
  }
]
EOF

# Apply CORS configuration
gsutil cors set cors.json gs://inspired-micron-474510-a3-public-media
```

### Step 3: Verify CORS Configuration

Test if CORS headers are present:

```bash
curl -I -H "Origin: http://localhost:64711" \
  https://storage.googleapis.com/inspired-micron-474510-a3-public-media/vendor_covers/1000116816_5evxmAP.jpg
```

You should see headers like:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, HEAD
```

### Step 4: Hot Restart Flutter App

After configuring CORS:
1. Stop the Flutter app (Ctrl+C)
2. Run again: `flutter run -d chrome --web-port=64711`
3. Check if images load

### Step 5: Alternative - Use a Proxy (If CORS Can't Be Fixed)

If you can't modify CORS settings, you can proxy images through your backend:

1. Add a proxy endpoint in Django:
```python
# views.py
from django.http import HttpResponse
import requests

def proxy_image(request, image_path):
    url = f"https://storage.googleapis.com/inspired-micron-474510-a3-public-media/{image_path}"
    response = requests.get(url)
    return HttpResponse(response.content, content_type=response.headers.get('Content-Type'))
```

2. Update Flutter to use proxy URLs:
```dart
// In ImageUtils, if CORS fails, use proxy
static String getImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  
  // If absolute URL from Google Cloud Storage, proxy through backend
  if (imageUrl.contains('storage.googleapis.com')) {
    final proxyUrl = imageUrl.replaceFirst(
      'https://storage.googleapis.com/inspired-micron-474510-a3-public-media/',
      '${AppConfig.baseUrl}/proxy-image/'
    );
    return proxyUrl;
  }
  
  // ... rest of the code
}
```

## Debugging

### Check What's Happening

1. **Browser Console (F12)**:
   - Look for image loading errors
   - Check Network tab to see if requests are being made
   - Check if requests are blocked (red in Network tab)

2. **Flutter Console**:
   - Look for debug messages starting with `🖼️` or `❌`
   - Check for CORS-related error messages

3. **Test Image URL Directly**:
   - Open: `https://storage.googleapis.com/inspired-micron-474510-a3-public-media/vendor_covers/1000116816_5evxmAP.jpg`
   - If it loads in browser but not in Flutter, it's a CORS issue

## Expected Behavior After Fix

- Images should load and display in restaurant cards
- Images should load and display in product cards
- No placeholder icons (fork and knife) should appear
- Console should show: `✅ Image loaded successfully: [URL]`

## Still Not Working?

If images still don't load after configuring CORS:

1. **Check bucket permissions**: Ensure bucket allows public read access
2. **Verify image URLs**: Make sure URLs are correct in the API response
3. **Check Flutter web build**: Try `flutter clean && flutter pub get && flutter run -d chrome`
4. **Try different browser**: Test in Firefox or Safari to rule out browser-specific issues

## Quick Test

After configuring CORS, test with this command:

```bash
curl -H "Origin: http://localhost:64711" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS \
  https://storage.googleapis.com/inspired-micron-474510-a3-public-media/vendor_covers/1000116816_5evxmAP.jpg
```

If CORS is configured correctly, you should get a `200 OK` response with CORS headers.

