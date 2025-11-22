# Mobile Testing Guide - Debug APK

## Current Configuration

✅ **Development (default):** `http://localhost:8000/api`  
✅ **Production:** `https://react-app-dot-inspired-micron-474510-a3.uc.r.appspot.com/api`

## ⚠️ Important Note for Mobile Testing

When testing on a **physical mobile device**, `localhost:8000` **will NOT work** because `localhost` on the mobile device refers to the device itself, not your computer running the backend server.

## Solution: Build Debug APK with Production URL

For testing on mobile, you have two options:

### Option 1: Use Production URL (Easiest)

Build the debug APK with the production URL:

```bash
flutter build apk --debug --dart-define=DEVELOPMENT=false
```

This will:
- Create a debug APK (`build/app/outputs/flutter-apk/app-debug.apk`)
- Use the production URL: `https://react-dot-inspired-micron-474510-a3.uc.r.appspot.com/api`
- Allow you to test all features against your production backend

**Install on device:**
```bash
# Connect your device via USB and install
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or manually transfer the APK file to your device and install it
```

### Option 2: Use Local Network IP (For Testing with Local Backend)

If you want to test against your local backend running on your computer:

1. **Find your computer's local IP address:**

   **On macOS/Linux:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Or:
   ```bash
   ipconfig getifaddr en0  # For Wi-Fi
   ```

   **On Windows:**
   ```bash
   ipconfig
   ```
   Look for "IPv4 Address" (usually something like `192.168.x.x` or `10.0.x.x`)

2. **Temporarily update `app_config.dart`:**
   
   Update the `devBaseUrl` to use your local IP:
   ```dart
   static const String devBaseUrl = 'http://192.168.x.x:8000/api'; // Replace with your IP
   ```

3. **Ensure your backend is accessible:**
   - Make sure your Django backend is running: `python manage.py runserver 0.0.0.0:8000`
   - The `0.0.0.0` makes it accessible from other devices on the network
   - Check firewall settings to allow port 8000

4. **Build debug APK:**
   ```bash
   flutter build apk --debug
   ```

5. **Install on device:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

## Build Commands Summary

### Debug APK with Production URL (Recommended for testing)
```bash
flutter build apk --debug --dart-define=DEVELOPMENT=false
```
- Location: `build/app/outputs/flutter-apk/app-debug.apk`
- Uses: Production URL
- Best for: Testing against production backend

### Debug APK with Development URL (Only works with local IP)
```bash
flutter build apk --debug
```
- Location: `build/app/outputs/flutter-apk/app-debug.apk`
- Uses: Development URL (must be local network IP, not localhost)
- Best for: Testing against local backend

### Release APK with Production URL
```bash
flutter build apk --release --dart-define=DEVELOPMENT=false
```
- Location: `build/app/outputs/flutter-apk/app-release.apk`
- Uses: Production URL
- Best for: Final production build

## Install APK on Device

### Method 1: Using ADB (USB Connection)
```bash
# Connect device via USB
# Enable USB Debugging on device
adb devices  # Verify device is connected
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Method 2: Manual Install
1. Copy `build/app/outputs/flutter-apk/app-debug.apk` to your device
2. On device: Settings → Security → Enable "Install from Unknown Sources"
3. Open the APK file on your device and install

## Verify Which URL is Being Used

After installing, check the app logs:
```bash
# View logs on connected device
adb logcat | grep -i "baseUrl\|API\|http"
```

Or add a debug print in your app code to see the configured URL.

## Troubleshooting

### APK not installing
- **Error: "App not installed"**
  - Make sure "Install from Unknown Sources" is enabled
  - Uninstall any previous version first: `adb uninstall com.example.food_delivery_app`

### Can't connect to backend
- **Using production URL:** Check internet connection on device
- **Using local IP:** 
  - Verify device and computer are on same Wi-Fi network
  - Check firewall settings (allow port 8000)
  - Ensure backend is running with `0.0.0.0:8000`

### Build fails
- Run `flutter clean` and try again
- Ensure all dependencies are installed: `flutter pub get`


