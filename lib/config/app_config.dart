/// App Configuration
/// 
/// This file contains environment-specific configuration for the app.
/// Update the base URLs according to your backend deployment.
class AppConfig {
  // Environment flag - set to false for production
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: true);

  // Base URLs
  // TODO: Update these URLs with your actual backend URLs
  // For development, use: http://localhost:8000 or http://127.0.0.1:8000
  // For production, use your Google App Engine URL
  static const String devBaseUrl = 'http://localhost:8000/api';
  static const String prodBaseUrl = 'https://react-app-dot-inspired-micron-474510-a3.uc.r.appspot.com/api';

  // Get the appropriate base URL based on environment
  static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;

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

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // OTP Configuration
  static const int otpLength = 6;
  static const int otpExpirySeconds = 300; // 5 minutes

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
}

