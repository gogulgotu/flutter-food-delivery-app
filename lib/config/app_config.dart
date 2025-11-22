/// App Configuration
/// 
/// This file contains environment-specific configuration for the app.
/// Update the base URLs according to your backend deployment.
/// 
/// To use production URL:
/// 1. Update prodBaseUrl below with your actual production URL
/// 2. Build with: flutter build apk --release --dart-define=DEVELOPMENT=false
/// 3. Or run with: flutter run --release --dart-define=DEVELOPMENT=false
/// 
/// See PRODUCTION_CONFIG.md for detailed instructions.
class AppConfig {
  // Environment flag - controlled via --dart-define=DEVELOPMENT=false at build time
  // Default is true (development mode)
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: true);

  // Base URLs
  // For development, use: http://localhost:8000 or http://127.0.0.1:8000
  static const String devBaseUrl = 'http://localhost:8000/api';
  
  // PRODUCTION URL - Update this with your actual production API URL
  // This URL is used when building with --dart-define=DEVELOPMENT=false
  static const String prodBaseUrl = 'https://react-app-dot-inspired-micron-474510-a3.uc.r.appspot.com/api';

  // Get the appropriate base URL based on environment
  // Returns devBaseUrl if isDevelopment is true, otherwise prodBaseUrl
  static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;

  // Media URL - Django serves media files from root/media/
  // Remove /api from base URL to get the root URL
  static String get mediaBaseUrl {
    if (isDevelopment) {
      return 'http://localhost:8000';
    } else {
      return 'https://react-app-dot-inspired-micron-474510-a3.uc.r.appspot.com';
    }
  }

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String vendorsEndpoint = '/vendors';
  static const String productsEndpoint = '/products';
  static const String ordersEndpoint = '/orders';
  static const String cartEndpoint = '/cart';
  static const String addressesEndpoint = '/addresses';
  static const String paymentsEndpoint = '/payments';
  static const String walletEndpoint = '/wallet';
  static const String notificationsEndpoint = '/notifications';
  static const String deliveryEndpoint = '/delivery';
  static const String dashboardEndpoint = '/dashboard';

  // Timeouts - Increased for better reliability
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // OTP Configuration
  static const int otpLength = 6;
  static const int otpExpirySeconds = 300; // 5 minutes

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
}

