# How to Apply CORS Configuration

## Your CORS Configuration File

You have a `cors.json` file with the correct configuration:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

## Method 1: Using Google Cloud Console (Easiest)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **Cloud Storage** → **Buckets**
3. Click on your bucket: `inspired-micron-474510-a3-public-media`
4. Click on the **Permissions** tab
5. Scroll down and click **Edit CORS configuration**
6. Copy and paste the contents of your `cors.json` file
7. Click **Save**

## Method 2: Using gsutil Command Line

If you have `gsutil` installed and authenticated:

```bash
cd /Users/gogul/Projects/flutter-food-delivery-app
gsutil cors set cors.json gs://inspired-micron-474510-a3-public-media
```

To verify it was applied:

```bash
gsutil cors get gs://inspired-micron-474510-a3-public-media
```

## Method 3: Using Google Cloud SDK (gcloud)

```bash
# Set CORS configuration
gcloud storage buckets update gs://inspired-micron-474510-a3-public-media \
  --cors-file=cors.json
```

## After Applying CORS

1. **Wait 1-2 minutes** for the CORS configuration to propagate
2. **Hot restart** your Flutter app (press `R` in terminal or restart)
3. **Clear browser cache** (Ctrl+Shift+Delete or Cmd+Shift+Delete)
4. **Check the console** - images should now load without CORS errors

## Verify CORS is Working

Test with curl:

```bash
curl -I -H "Origin: http://localhost:64711" \
  https://storage.googleapis.com/inspired-micron-474510-a3-public-media/vendor_covers/1000116816_5evxmAP.jpg
```

You should see:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, HEAD
```

## Current Status

From your logs:
- ✅ PNG and JPG images are loading successfully initially
- ❌ WebP images are failing with CORS errors
- ❌ Some images fail on subsequent loads

After applying CORS, all images should load consistently.

