# Quick Setup Guide

## Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Backend API running (or use production URL)

## Installation Steps

### 1. Install Dependencies

```bash
cd flutter-food-delivery-app
flutter pub get
```

### 2. Configure API Base URL

Open `lib/config/app_config.dart` and update:

```dart
// For local development
static const String devBaseUrl = 'http://localhost:8000/api';
// or
static const String devBaseUrl = 'http://127.0.0.1:8000/api';

// For production (update with your actual URL)
static const String prodBaseUrl = 'https://react-app-dot-inspired-micron-474510-a3.uc.r.appspot.com/api';
```

**Important:** Replace the production URL with your actual Google App Engine URL.

### 3. Run the App

```bash
# For development
flutter run

# For specific platform
flutter run -d android
flutter run -d ios
```

## Testing Authentication

### Development Mode

1. Enter any valid Indian mobile number (format: +91XXXXXXXXXX)
2. Click "Send OTP"
3. Check the API response or console logs for the OTP (in development, OTP is returned in response)
4. Enter the OTP to login

### Production Mode

1. Enter your registered mobile number
2. Click "Send OTP"
3. Check your SMS for the OTP
4. Enter the OTP to login

## User Roles

The app automatically detects user role from the backend response:

- **Customer** → Navigates to Customer Dashboard
- **Vendor/Hotel Owner** → Navigates to Vendor Dashboard  
- **Delivery Person** → Navigates to Delivery Dashboard

## Project Structure Overview

```
lib/
├── config/          # App configuration (API URLs, endpoints)
├── models/          # Data models (User, AuthResponse, etc.)
├── services/        # API service and storage service
├── providers/       # State management (AuthProvider)
├── screens/         # All app screens
│   ├── auth/        # Authentication screens
│   ├── customer/    # Customer dashboard
│   ├── vendor/      # Vendor dashboard
│   └── delivery/    # Delivery dashboard
└── utils/           # Utility functions
```

## Key Files

- `lib/main.dart` - App entry point
- `lib/config/app_config.dart` - API configuration
- `lib/services/api_service.dart` - All API calls
- `lib/providers/auth_provider.dart` - Authentication state
- `lib/screens/splash_screen.dart` - Initial routing logic

## Next Steps

1. **Complete Dashboard Features:**
   - Integrate restaurant listing API
   - Add order management
   - Implement cart functionality

2. **Add More Features:**
   - Push notifications
   - Real-time order tracking
   - Payment integration
   - Profile management

3. **Testing:**
   - Write unit tests
   - Add widget tests
   - Integration testing

## Troubleshooting

### Issue: Cannot connect to API

**Solution:** 
- Check if backend server is running
- Verify base URL in `app_config.dart`
- Check network connectivity
- For Android emulator, use `10.0.2.2` instead of `localhost`

### Issue: OTP not received

**Solution:**
- In development, check API response for OTP
- In production, verify SMS service is configured
- Check mobile number format (+91XXXXXXXXXX)

### Issue: Token expiration errors

**Solution:**
- Token refresh is automatic
- If refresh fails, user will be logged out
- Check refresh token endpoint is working

## API Endpoints Used

- `POST /api/auth/send-otp/` - Send OTP
- `POST /api/auth/verify-otp/` - Verify OTP
- `POST /api/auth/token/refresh/` - Refresh token
- `GET /api/dashboard/home/` - Vendor dashboard
- `GET /api/delivery/dashboard/` - Delivery dashboard

For complete API documentation, see:
- `flutter_documentation/api_documentation/ENDPOINTS.md`
- `flutter_documentation/api_documentation/AUTHENTICATION.md`

## Support

For issues or questions, refer to:
- `PROJECT_STRUCTURE.md` - Detailed project documentation
- API documentation in `flutter_documentation/` folder

