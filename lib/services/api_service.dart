import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/auth_response_model.dart';
import '../services/storage_service.dart';

/// API Service
/// 
/// Handles all HTTP requests to the backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for token management
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to requests
          final token = await StorageService().getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request
              final opts = error.requestOptions;
              final token = await StorageService().getAccessToken();
              if (token != null) {
                opts.headers['Authorization'] = 'Bearer $token';
              }
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              // Refresh failed, clear storage and redirect to login
              await StorageService().clearAll();
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  late Dio _dio;
  final StorageService _storageService = StorageService();

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '${AppConfig.authEndpoint}/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] as String;
        await _storageService.saveAccessToken(newAccessToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== Authentication Endpoints ====================

  /// Send OTP to mobile number
  /// 
  /// [mobileNumber] - Mobile number in format +919876543210
  /// Returns OtpSendResponseModel
  Future<OtpSendResponseModel> sendOtp(String mobileNumber) async {
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/send-otp/',
        data: {'mobile_number': mobileNumber},
      );

      return OtpSendResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP and get tokens
  /// 
  /// [mobileNumber] - Mobile number in format +919876543210
  /// [otp] - 6-digit OTP code
  /// Returns AuthResponseModel with user data and tokens
  Future<AuthResponseModel> verifyOtp(String mobileNumber, String otp) async {
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/verify-otp/',
        data: {
          'mobile_number': mobileNumber,
          'otp': otp,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // Save tokens and user data
      await _storageService.saveTokens(
        authResponse.tokens.access,
        authResponse.tokens.refresh,
      );
      await _storageService.saveUserData(authResponse.user);

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user profile
  /// 
  /// Returns UserModel with current user's profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('${AppConfig.usersEndpoint}/profile/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Vendor Endpoints ====================

  /// Get list of vendors
  Future<Map<String, dynamic>> getVendors({
    String? category,
    String? search,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        AppConfig.vendorsEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Dashboard Endpoints ====================

  /// Get vendor dashboard data
  /// 
  /// Returns dashboard statistics for hotel owner
  Future<Map<String, dynamic>> getVendorDashboard() async {
    try {
      final response = await _dio.get('${AppConfig.dashboardEndpoint}/home/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get delivery person dashboard data
  /// 
  /// Returns dashboard data for delivery person
  Future<Map<String, dynamic>> getDeliveryDashboard() async {
    try {
      final response = await _dio.get('${AppConfig.deliveryEndpoint}/dashboard/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Error Handling ====================

  /// Handle API errors
  String _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      if (data is Map<String, dynamic>) {
        // Try to extract error message
        if (data.containsKey('detail')) {
          return data['detail'] as String;
        } else if (data.containsKey('message')) {
          return data['message'] as String;
        } else if (data.containsKey('error')) {
          return data['error'] as String;
        }
      }

      switch (statusCode) {
        case 400:
          return 'Bad request. Please check your input.';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Forbidden. You do not have permission.';
        case 404:
          return 'Resource not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'An error occurred. Status code: $statusCode';
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'An unexpected error occurred: ${error.message}';
    }
  }
}

