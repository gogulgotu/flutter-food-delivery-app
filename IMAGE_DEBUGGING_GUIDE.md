# Image Display Debugging Guide

This guide helps diagnose and fix image display issues between Django REST API and Flutter.

## Common Issues and Solutions

### 1. Image URLs Not Loading

**Symptoms:**
- Images show placeholder/error icon
- Console shows network errors
- Images load in browser but not in app

**Possible Causes:**

#### A. Relative URL Path Issue
**Problem:** Django returns relative URLs like `/media/vendor/image.jpg` but Flutter needs full URLs.

**Solution:** The `ImageUtils.getImageUrl()` function automatically handles this by:
- Detecting if URL is absolute (starts with http:// or https://)
- Converting relative URLs to full URLs using the media base URL
- Handling different URL formats

**Check:**
```dart
// In your code, verify the URL construction
final fullUrl = ImageUtils.getImageUrl(vendor.image);
print('Full URL: $fullUrl');
```

#### B. CORS (Cross-Origin Resource Sharing) Issues
**Problem:** Browser/Flutter blocks requests due to CORS policy.

**Django Solution:** Add CORS headers in Django settings:
```python
# settings.py
INSTALLED_APPS = [
    ...
    'corsheaders',
]

MIDDLEWARE = [
    ...
    'corsheaders.middleware.CorsMiddleware',
    ...
]

# Allow all origins (for development only)
CORS_ALLOW_ALL_ORIGINS = True

# Or specify allowed origins for production
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]

# Allow credentials
CORS_ALLOW_CREDENTIALS = True
```

#### C. Media File Serving Configuration
**Problem:** Django not serving media files correctly.

**Django Solution:** Ensure proper media configuration:
```python
# settings.py
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# urls.py (for development)
from django.conf import settings
from django.conf.urls.static import static

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

**For Production (Google App Engine):**
- Use Google Cloud Storage for media files
- Configure MEDIA_URL to point to Cloud Storage bucket
- Ensure bucket has public read permissions

### 2. Image URL Format Issues

**Check API Response:**
```json
{
  "id": "uuid",
  "name": "Restaurant Name",
  "image": "/media/vendor/image.jpg"  // Relative URL
  // OR
  "image": "https://example.com/media/vendor/image.jpg"  // Absolute URL
}
```

**The ImageUtils handles both formats automatically.**

### 3. Network/Timeout Issues

**Symptoms:**
- Images load slowly or timeout
- Intermittent image loading failures

**Solution:**
- Timeouts are configured in `AppConfig` (60 seconds)
- `CachedNetworkImage` provides automatic retry and caching
- Check network connectivity

### 4. Authentication Required for Images

**Problem:** Images require authentication headers.

**Solution:** Update `ImageUtils.buildNetworkImage()` to include auth headers:
```dart
httpHeaders: {
  'Accept': 'image/*',
  'Authorization': 'Bearer $token',  // Add if needed
},
```

## Debugging Steps

### Step 1: Verify API Response
```dart
// Add debug print in your provider/model
print('Vendor image URL from API: ${vendor.image}');
```

### Step 2: Check URL Construction
```dart
// Use debug utility
ImageUtils.debugImageUrl(vendor.image);
```

### Step 3: Test URL in Browser
1. Copy the full URL from debug output
2. Paste in browser address bar
3. If it loads in browser but not in app, check CORS

### Step 4: Check Network Logs
- Enable Flutter network logging
- Check for 404, 403, or CORS errors
- Verify request headers

### Step 5: Verify Media Base URL
```dart
// Check if media base URL is correct
print('Media Base URL: ${AppConfig.mediaBaseUrl}');
// Should match your Django server URL
```

## Testing Checklist

- [ ] API returns image URLs in response
- [ ] Image URLs are valid (not null/empty)
- [ ] Full URL construction is correct
- [ ] Django serves media files (test in browser)
- [ ] CORS headers are configured
- [ ] Network connectivity is working
- [ ] Image files exist in Django media directory
- [ ] File permissions are correct
- [ ] Image format is supported (jpg, png, webp)

## Production Considerations

1. **Use CDN/Cloud Storage:** Store images in Google Cloud Storage or AWS S3
2. **Image Optimization:** Compress images on backend
3. **Caching:** Use `CachedNetworkImage` (already implemented)
4. **Error Handling:** Show appropriate placeholders
5. **Lazy Loading:** Load images as user scrolls
6. **Image Sizing:** Request appropriately sized images

## Example: Verifying Image URL

```dart
// In your widget
Widget build(BuildContext context) {
  final vendor = ...;
  
  // Debug the URL
  ImageUtils.debugImageUrl(vendor.image);
  
  // Use the utility to build image
  return ImageUtils.buildNetworkImage(
    imageUrl: vendor.image,
    width: 200,
    height: 200,
  );
}
```

## Common Django Settings for Media Files

```python
# settings.py
import os

BASE_DIR = Path(__file__).resolve().parent.parent

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# For production with Google Cloud Storage
# DEFAULT_FILE_STORAGE = 'storages.backends.gcloud.GoogleCloudStorage'
# GS_BUCKET_NAME = 'your-bucket-name'
# MEDIA_URL = f'https://storage.googleapis.com/{GS_BUCKET_NAME}/'
```

## Troubleshooting Commands

```bash
# Check if Django is serving media files
curl http://localhost:8000/media/vendor/image.jpg

# Check CORS headers
curl -I http://localhost:8000/api/vendors/

# Test image URL from Flutter
# Use ImageUtils.debugImageUrl() in your code
```

