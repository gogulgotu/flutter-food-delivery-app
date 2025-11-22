# Production API Configuration Guide

This guide explains how to configure the Flutter app to use the production API base URL.

## Current Configuration

The app configuration is located in `lib/config/app_config.dart`. The app uses environment variables to determine whether to use development or production URLs.

### Configuration File Location
```
lib/config/app_config.dart
```

### Current Setup

```dart
// Environment flag - set to false for production
static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: true);

// Base URLs
static const String devBaseUrl = 'http://localhost:8000/api';
static const String prodBaseUrl = 'https://react-app-dot-inspired-micron-474510-a3.uc.r.appspot.com/api';

// Get the appropriate base URL based on environment
static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;
```

## Method 1: Update Production URL (Recommended)

### Step 1: Update the Production URL

Edit `lib/config/app_config.dart` and replace the `prodBaseUrl` with your actual production URL:

```dart
static const String prodBaseUrl = 'https://your-production-domain.com/api';
```

Also update the `mediaBaseUrl`:

```dart
static String get mediaBaseUrl {
  if (isDevelopment) {
    return 'http://localhost:8000';
  } else {
    return 'https://your-production-domain.com'; // Remove /api from production URL
  }
}
```

### Step 2: Build for Production

When building for production, pass the `DEVELOPMENT=false` flag:

#### Android (APK)
```bash
flutter build apk --release --dart-define=DEVELOPMENT=false
```

#### Android (App Bundle)
```bash
flutter build appbundle --release --dart-define=DEVELOPMENT=false
```

#### iOS
```bash
flutter build ios --release --dart-define=DEVELOPMENT=false
```

#### Run in Production Mode (for testing)
```bash
flutter run --release --dart-define=DEVELOPMENT=false
```

## Method 2: Change Default Behavior (Alternative)

If you want production to be the default, you can modify `app_config.dart`:

```dart
// Change default to false for production
static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: false);
```

**Note:** With this change, development builds will need to explicitly pass `--dart-define=DEVELOPMENT=true`.

## Method 3: Using Build Variants (Advanced)

For Android, you can create build variants that automatically set the environment. Create or edit `android/app/build.gradle.kts`:

```kotlin
android {
    // ... existing configuration ...
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
        
        // Add debug with production URL variant
        create("debugProd") {
            initWith(getByName("debug"))
            matchingFallbacks.add("debug")
        }
    }
    
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
        }
        create("prod") {
            dimension = "environment"
        }
    }
}
```

Then build with:
```bash
flutter build apk --release --flavor prod
```

## Verification

After building, you can verify which URL is being used by checking the app logs:

1. Run the app in release mode
2. Check the console output for API requests
3. The base URL should match your production URL

## Quick Reference Commands

### Development Build (uses localhost)
```bash
flutter run
# or explicitly
flutter run --dart-define=DEVELOPMENT=true
```

### Production Build (uses production URL)
```bash
# Android APK
flutter build apk --release --dart-define=DEVELOPMENT=false

# Android App Bundle (for Play Store)
flutter build appbundle --release --dart-define=DEVELOPMENT=false

# iOS
flutter build ios --release --dart-define=DEVELOPMENT=false

# Test production build locally
flutter run --release --dart-define=DEVELOPMENT=false
```

## Important Notes

1. **Always update `prodBaseUrl`**: Make sure to replace the placeholder production URL with your actual production API URL.

2. **Media URLs**: The `mediaBaseUrl` is automatically derived from the base URL (removes `/api`), but verify it matches your backend's media serving configuration.

3. **CORS Settings**: Ensure your production backend has CORS configured to accept requests from your Flutter app.

4. **HTTPS Required**: Production URLs must use HTTPS. The app may not work correctly with HTTP in production due to security policies.

5. **Testing**: Always test the production build thoroughly before deploying to app stores.

## Troubleshooting

### App still using development URL in production build

**Solution**: Ensure you're passing the `--dart-define=DEVELOPMENT=false` flag during the build command.

### API calls failing in production

**Checklist**:
- ✅ Production URL is correct and accessible
- ✅ HTTPS is properly configured
- ✅ CORS is enabled for your app's domain
- ✅ Backend API is running and accessible
- ✅ Media URLs are correctly configured

### Verify current environment at runtime

You can add a debug print in your app to check which URL is being used:

```dart
import 'package:flutter/foundation.dart';
import 'config/app_config.dart';

void checkEnvironment() {
  if (kDebugMode) {
    print('🔧 Current Environment: ${AppConfig.isDevelopment ? "Development" : "Production"}');
    print('🔗 Base URL: ${AppConfig.baseUrl}');
    print('📸 Media URL: ${AppConfig.mediaBaseUrl}');
  }
}
```

