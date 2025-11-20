# Flutter Food Delivery App - Project Structure

## Overview

This is a complete, production-ready Flutter application for a multi-role food delivery system. The app supports three distinct user roles: **Customer**, **Vendor (Restaurant Owner)**, and **Delivery Person**, all from a single codebase.

## Features

- ✅ OTP-based authentication using Indian mobile numbers
- ✅ Role-based routing and dashboards
- ✅ JWT token management with automatic refresh
- ✅ Secure storage for tokens and user data
- ✅ State management using Provider
- ✅ API integration layer with error handling
- ✅ Support for both development and production environments

## Project Structure

```
lib/
├── config/
│   └── app_config.dart              # Environment configuration and API endpoints
├── models/
│   ├── user_model.dart              # User model with role information
│   └── auth_response_model.dart     # Authentication response models
├── services/
│   ├── api_service.dart             # HTTP client and API calls
│   └── storage_service.dart         # Secure storage for tokens and user data
├── providers/
│   └── auth_provider.dart           # Authentication state management
├── screens/
│   ├── splash_screen.dart           # Initial screen with auth check
│   ├── auth/
│   │   ├── phone_number_screen.dart # Phone number input screen
│   │   └── otp_screen.dart          # OTP verification screen
│   ├── customer/
│   │   └── customer_dashboard_screen.dart  # Customer dashboard
│   ├── vendor/
│   │   └── vendor_dashboard_screen.dart    # Vendor/Restaurant owner dashboard
│   └── delivery/
│       └── delivery_dashboard_screen.dart  # Delivery person dashboard
└── utils/
    ├── route_utils.dart             # Role-based routing utilities
    └── phone_utils.dart             # Phone number validation utilities
```

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure API Base URLs

Edit `lib/config/app_config.dart` and update the base URLs:

```dart
// For development
static const String devBaseUrl = 'http://localhost:8000/api';
// or
static const String devBaseUrl = 'http://127.0.0.1:8000/api';

// For production
static const String prodBaseUrl = 'https://your-production-url.com/api';
```

**Note:** Update the production URL with your actual Google App Engine URL based on your CORS settings.

### 3. Environment Configuration

The app automatically detects the environment. To switch between development and production:

- **Development (default):** Uses `devBaseUrl`
- **Production:** Set `isDevelopment = false` in `app_config.dart` or use build flags

### 4. Run the App

```bash
# Development
flutter run

# Production build
flutter build apk --release
# or
flutter build ios --release
```

## Authentication Flow

1. **Splash Screen** → Checks if user is authenticated
2. **Phone Number Screen** → User enters mobile number
3. **OTP Screen** → User enters 6-digit OTP
4. **Role Detection** → Backend returns user role in auth response
5. **Dashboard Navigation** → User is routed to role-specific dashboard

## User Roles

### Customer
- Browse restaurants and menu items
- Place orders
- Track orders
- Manage addresses and payment methods
- View order history

### Vendor (Restaurant Owner)
- View dashboard statistics
- Manage orders
- Manage menu items
- View analytics
- Update restaurant status

### Delivery Person
- View active delivery assignments
- Toggle online/offline status
- View earnings and statistics
- Track delivery history

## API Integration

### Authentication Endpoints

The app integrates with the following endpoints:

- `POST /api/auth/send-otp/` - Send OTP to mobile number
- `POST /api/auth/verify-otp/` - Verify OTP and get tokens
- `POST /api/auth/token/refresh/` - Refresh access token

### Dashboard Endpoints

- **Vendor:** `GET /api/dashboard/home/` - Get vendor dashboard data
- **Delivery:** `GET /api/delivery/dashboard/` - Get delivery dashboard data

### Token Management

- Access tokens are automatically added to all authenticated requests
- Token refresh is handled automatically on 401 errors
- Tokens are stored securely using `flutter_secure_storage`

## State Management

The app uses **Provider** for state management:

- `AuthProvider` - Manages authentication state, user data, and login/logout operations

## Storage

- **Secure Storage** (`flutter_secure_storage`): Stores JWT tokens
- **Shared Preferences** (`shared_preferences`): Stores user data and login status

## Key Integration Points

### 1. API Service (`lib/services/api_service.dart`)

All API calls are made through the `ApiService` class. To add new endpoints:

```dart
Future<YourModel> yourEndpoint() async {
  try {
    final response = await _dio.get('/your-endpoint/');
    return YourModel.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

### 2. Models (`lib/models/`)

Add new models for API responses. Follow the pattern:

```dart
class YourModel {
  // Properties
  factory YourModel.fromJson(Map<String, dynamic> json) {
    // Parse JSON
  }
  Map<String, dynamic> toJson() {
    // Convert to JSON
  }
}
```

### 3. Dashboards

Each dashboard screen has placeholder implementations. To integrate with APIs:

- **Customer Dashboard:** Add API calls to fetch restaurants, products, orders
- **Vendor Dashboard:** Already integrated with `GET /api/dashboard/home/`
- **Delivery Dashboard:** Already integrated with `GET /api/delivery/dashboard/`

## Environment Variables

Currently, environment is controlled via `AppConfig.isDevelopment`. For more advanced setup, consider using:

- `flutter_dotenv` package
- Build configuration files
- Environment-specific config files

## Testing

To test the app:

1. **Development Mode:**
   - OTP is returned in API response (check logs)
   - Use any valid Indian mobile number format: `+91XXXXXXXXXX`

2. **Production Mode:**
   - OTP is sent via SMS
   - Ensure backend SMS service is configured

## Troubleshooting

### Common Issues

1. **API Connection Errors:**
   - Check base URL in `app_config.dart`
   - Verify backend server is running
   - Check network connectivity

2. **Token Expiration:**
   - Token refresh is automatic
   - If refresh fails, user is logged out automatically

3. **OTP Not Received:**
   - In development, check API response for OTP
   - In production, verify SMS service configuration

## Next Steps

1. **Complete Dashboard Implementations:**
   - Add API calls for restaurants, products, orders
   - Implement order management features
   - Add real-time updates

2. **Additional Features:**
   - Push notifications
   - Real-time order tracking
   - Payment integration
   - Address management
   - Profile editing

3. **Testing:**
   - Unit tests for models and services
   - Widget tests for screens
   - Integration tests for authentication flow

## Dependencies

Key dependencies used:

- `provider` - State management
- `dio` - HTTP client
- `flutter_secure_storage` - Secure token storage
- `shared_preferences` - Local storage
- `intl_phone_field` - Phone number input
- `intl` - Internationalization

## Support

For API documentation, refer to:
- `flutter_documentation/api_documentation/ENDPOINTS.md`
- `flutter_documentation/api_documentation/AUTHENTICATION.md`
- `flutter_documentation/swagger/openapi.yaml`

## License

[Your License Here]

