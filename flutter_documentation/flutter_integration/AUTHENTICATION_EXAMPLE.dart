// Authentication Example for Flutter
// Complete authentication flow implementation

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/models/user.dart';
import '../core/services/auth_service.dart';

/// Authentication Manager
/// Handles all authentication-related operations
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();
  
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SharedPreferences? _prefs = null; // Initialize in init()
  
  User? _currentUser;
  bool _isAuthenticated = false;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  
  /// Initialize authentication manager
  Future<void> init() async {
    // Check if user is already logged in
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      try {
        // Verify token is still valid by fetching user profile
        final userService = UserService();
        _currentUser = await userService.getProfile();
        _isAuthenticated = true;
      } catch (e) {
        // Token invalid, clear storage
        await logout();
      }
    }
  }
  
  /// Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      // Check if OTP verification is required
      if (response['requires_otp_verification'] == true) {
        return AuthResult(
          success: true,
          requiresOTP: true,
          message: response['message'] ?? 'Registration successful. Please verify OTP.',
        );
      }
      
      return AuthResult(
        success: true,
        message: 'Registration successful',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _getErrorMessage(e),
      );
    }
  }
  
  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      
      // Store tokens
      await _storeTokens(
        accessToken: response['access'],
        refreshToken: response['refresh'],
      );
      
      // Store user data
      if (response['user'] != null) {
        _currentUser = User.fromJson(response['user']);
        _isAuthenticated = true;
      }
      
      return AuthResult(
        success: true,
        user: _currentUser,
        message: 'Login successful',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _getErrorMessage(e),
      );
    }
  }
  
  /// Send OTP to mobile number
  Future<AuthResult> sendOTP(String mobileNumber) async {
    try {
      final response = await _authService.sendOTP(mobileNumber);
      
      // In development, OTP is returned in response
      // In production, it's sent via SMS
      String? otp;
      if (response.containsKey('otp')) {
        otp = response['otp'];
      }
      
      return AuthResult(
        success: true,
        message: response['message'] ?? 'OTP sent successfully',
        otp: otp, // Only in development
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _getErrorMessage(e),
      );
    }
  }
  
  /// Verify OTP and login
  Future<AuthResult> verifyOTP({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await _authService.verifyOTP(
        mobileNumber: mobileNumber,
        otp: otp,
      );
      
      // Store tokens
      if (response['tokens'] != null) {
        await _storeTokens(
          accessToken: response['tokens']['access'],
          refreshToken: response['tokens']['refresh'],
        );
      }
      
      // Store user data
      if (response['user'] != null) {
        _currentUser = User.fromJson(response['user']);
        _isAuthenticated = true;
      }
      
      return AuthResult(
        success: true,
        user: _currentUser,
        isNewUser: response['user_type'] == 'new',
        message: 'OTP verified successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: _getErrorMessage(e),
      );
    }
  }
  
  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final newAccessToken = await _authService.refreshToken(refreshToken);
      await _secureStorage.write(key: 'access_token', value: newAccessToken);
      return true;
    } catch (e) {
      // Refresh failed, clear tokens
      await logout();
      return false;
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    // Clear tokens
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    
    // Clear user data
    _currentUser = null;
    _isAuthenticated = false;
    
    // Clear any cached data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  /// Store tokens securely
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }
  
  /// Get error message from exception
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    } else if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map) {
          return data['error'] ?? 
                 data['detail'] ?? 
                 'An error occurred';
        }
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }
}

/// Authentication Result
class AuthResult {
  final bool success;
  final User? user;
  final String? message;
  final String? error;
  final bool requiresOTP;
  final bool isNewUser;
  final String? otp; // Only in development
  
  AuthResult({
    required this.success,
    this.user,
    this.message,
    this.error,
    this.requiresOTP = false,
    this.isNewUser = false,
    this.otp,
  });
}

/// Usage Example with Provider/State Management
/// 
/// ```dart
/// class AuthProvider extends ChangeNotifier {
///   final AuthManager _authManager = AuthManager();
///   
///   User? get user => _authManager.currentUser;
///   bool get isAuthenticated => _authManager.isAuthenticated;
///   
///   Future<void> login(String email, String password) async {
///     final result = await _authManager.login(
///       email: email,
///       password: password,
///     );
///     
///     if (result.success) {
///       notifyListeners();
///     } else {
///       throw Exception(result.error);
///     }
///   }
///   
///   Future<void> logout() async {
///     await _authManager.logout();
///     notifyListeners();
///   }
/// }
/// ```

/// OTP Login Flow Example
/// 
/// ```dart
/// class OTPLoginScreen extends StatefulWidget {
///   @override
///   _OTPLoginScreenState createState() => _OTPLoginScreenState();
/// }
/// 
/// class _OTPLoginScreenState extends State<OTPLoginScreen> {
///   final AuthManager _authManager = AuthManager();
///   final TextEditingController _phoneController = TextEditingController();
///   final TextEditingController _otpController = TextEditingController();
///   bool _otpSent = false;
///   bool _loading = false;
///   
///   Future<void> _sendOTP() async {
///     setState(() => _loading = true);
///     
///     final result = await _authManager.sendOTP(_phoneController.text);
///     
///     setState(() {
///       _loading = false;
///       if (result.success) {
///         _otpSent = true;
///         // Show OTP in development
///         if (result.otp != null) {
///           _otpController.text = result.otp!;
///         }
///       } else {
///         // Show error
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text(result.error ?? 'Failed to send OTP')),
///         );
///       }
///     });
///   }
///   
///   Future<void> _verifyOTP() async {
///     setState(() => _loading = true);
///     
///     final result = await _authManager.verifyOTP(
///       mobileNumber: _phoneController.text,
///       otp: _otpController.text,
///     );
///     
///     setState(() => _loading = false);
///     
///     if (result.success) {
///       // Navigate to home
///       Navigator.pushReplacementNamed(context, '/home');
///     } else {
///       // Show error
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(result.error ?? 'Invalid OTP')),
///       );
///     }
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Padding(
///         padding: EdgeInsets.all(16),
///         child: Column(
///           children: [
///             TextField(
///               controller: _phoneController,
///               keyboardType: TextInputType.phone,
///               decoration: InputDecoration(labelText: 'Phone Number'),
///             ),
///             if (_otpSent) ...[
///               SizedBox(height: 16),
///               TextField(
///                 controller: _otpController,
///                 keyboardType: TextInputType.number,
///                 decoration: InputDecoration(labelText: 'OTP'),
///               ),
///               ElevatedButton(
///                 onPressed: _loading ? null : _verifyOTP,
///                 child: Text('Verify OTP'),
///               ),
///             ] else ...[
///               SizedBox(height: 16),
///               ElevatedButton(
///                 onPressed: _loading ? null : _sendOTP,
///                 child: Text('Send OTP'),
///               ),
///             ],
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```

/// Token Refresh Interceptor Example
/// 
/// The token refresh is handled automatically by the AuthInterceptor
/// in the HTTP client setup. However, you can also manually refresh:
/// 
/// ```dart
/// Future<void> ensureAuthenticated() async {
///   final authManager = AuthManager();
///   
///   if (!authManager.isAuthenticated) {
///     // Try to refresh token
///     final refreshed = await authManager.refreshAccessToken();
///     if (!refreshed) {
///       // Redirect to login
///       Navigator.pushNamedAndRemoveUntil(
///         context,
///         '/login',
///         (route) => false,
///       );
///     }
///   }
/// }
/// ```

