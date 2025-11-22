import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    bool? isFeatured,
    String? category,
    String? search,
    double? minRating,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isFeatured != null) queryParams['is_featured'] = isFeatured;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (minRating != null) queryParams['min_rating'] = minRating;
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

  /// Get vendor details by slug
  Future<Map<String, dynamic>> getVendorDetails(String slug) async {
    try {
      final response = await _dio.get('${AppConfig.vendorsEndpoint}/$slug/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Product Endpoints ====================

  /// Get list of products
  Future<Map<String, dynamic>> getProducts({
    bool? isFeatured,
    String? vendor,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? isAvailable,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isFeatured != null) queryParams['is_featured'] = isFeatured;
      if (vendor != null) queryParams['vendor'] = vendor;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (isAvailable != null) queryParams['is_available'] = isAvailable;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        AppConfig.productsEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get product details by slug
  Future<Map<String, dynamic>> getProductDetails(String slug) async {
    try {
      final response = await _dio.get('${AppConfig.productsEndpoint}/$slug/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get product categories
  Future<List<dynamic>> getProductCategories() async {
    try {
      debugPrint('🟢 Fetching product categories from: /product-categories/');
      final response = await _dio.get('/product-categories/');
      debugPrint('🟢 Product categories response status: ${response.statusCode}');
      debugPrint('🟢 Product categories response type: ${response.data.runtimeType}');
      
      // Handle paginated response (if API returns {results: [...]})
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('🟢 Product categories: Map response with keys: ${data.keys.toList()}');
        if (data.containsKey('results') && data['results'] is List) {
          final results = data['results'] as List;
          debugPrint('✅ Product categories: Paginated response with ${results.length} items');
          return results;
        } else if (data.containsKey('data') && data['data'] is List) {
          final results = data['data'] as List;
          debugPrint('✅ Product categories: Data key response with ${results.length} items');
          return results;
        } else {
          debugPrint('⚠️ Product categories: Map response but no results/data key found');
          debugPrint('   Map content: $data');
        }
      }
      
      // Handle direct list response
      if (response.data is List) {
        final list = response.data as List;
        debugPrint('✅ Product categories: Direct list response with ${list.length} items');
        return list;
      }
      
      debugPrint('❌ Product categories: Unexpected response format: ${response.data.runtimeType}');
      debugPrint('   Response data: ${response.data}');
      return [];
    } on DioException catch (e) {
      final error = _handleError(e);
      debugPrint('❌ Error fetching product categories: $error');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      return [];
    } catch (e) {
      debugPrint('❌ Unexpected error fetching product categories: $e');
      return [];
    }
  }

  /// Get vendor categories
  Future<List<dynamic>> getVendorCategories() async {
    try {
      debugPrint('🔵 Fetching vendor categories from: /vendor-categories/');
      final response = await _dio.get('/vendor-categories/');
      debugPrint('🔵 Vendor categories response status: ${response.statusCode}');
      debugPrint('🔵 Vendor categories response type: ${response.data.runtimeType}');
      
      // Handle paginated response (if API returns {results: [...]})
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('🔵 Vendor categories: Map response with keys: ${data.keys.toList()}');
        if (data.containsKey('results') && data['results'] is List) {
          final results = data['results'] as List;
          debugPrint('✅ Vendor categories: Paginated response with ${results.length} items');
          return results;
        } else if (data.containsKey('data') && data['data'] is List) {
          final results = data['data'] as List;
          debugPrint('✅ Vendor categories: Data key response with ${results.length} items');
          return results;
        } else {
          debugPrint('⚠️ Vendor categories: Map response but no results/data key found');
          debugPrint('   Map content: $data');
        }
      }
      
      // Handle direct list response
      if (response.data is List) {
        final list = response.data as List;
        debugPrint('✅ Vendor categories: Direct list response with ${list.length} items');
        return list;
      }
      
      debugPrint('❌ Vendor categories: Unexpected response format: ${response.data.runtimeType}');
      debugPrint('   Response data: ${response.data}');
      return [];
    } on DioException catch (e) {
      final error = _handleError(e);
      debugPrint('❌ Error fetching vendor categories: $error');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      return [];
    } catch (e) {
      debugPrint('❌ Unexpected error fetching vendor categories: $e');
      return [];
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

  // ==================== Customer Dashboard Endpoints ====================

  /// Get home data (featured vendors, categories, promotions, popular products)
  /// 
  /// [latitude] - Optional user latitude
  /// [longitude] - Optional user longitude
  Future<Map<String, dynamic>> getHomeData({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      final response = await _dio.get(
        '/home-data/',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get wallet balance
  /// 
  /// Returns wallet information with current balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final response = await _dio.get('${AppConfig.walletEndpoint}/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get wallet transactions
  /// 
  /// [page] - Page number for pagination
  /// [pageSize] - Number of items per page
  Future<Map<String, dynamic>> getWalletTransactions({
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        '${AppConfig.walletEndpoint}/transactions/',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get notifications
  /// 
  /// [page] - Page number for pagination
  /// [isRead] - Filter by read status (optional)
  Future<Map<String, dynamic>> getNotifications({
    int? page,
    bool? isRead,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (isRead != null) queryParams['is_read'] = isRead;

      final response = await _dio.get(
        AppConfig.notificationsEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await _dio.post(
        '${AppConfig.notificationsEndpoint}/mark-all-read/',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get customer orders
  /// 
  /// [status] - Filter by order status
  /// [page] - Page number for pagination
  /// [pageSize] - Number of items per page
  Future<Map<String, dynamic>> getOrders({
    String? status,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        AppConfig.ordersEndpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Cart Endpoints ====================

  /// Get user's cart for a vendor
  Future<Map<String, dynamic>> getCart(String vendorId) async {
    try {
      debugPrint('🟢 Fetching cart from: ${AppConfig.cartEndpoint}?vendor=$vendorId');
      final response = await _dio.get(
        AppConfig.cartEndpoint,
        queryParameters: {'vendor': vendorId},
      );
      debugPrint('🟢 Cart response status: ${response.statusCode}');
      debugPrint('🟢 Cart raw response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final error = _handleError(e);
      debugPrint('❌ Error fetching cart: $error');
      throw error;
    }
  }

  /// Add item to cart
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
  }) async {
    try {
      final data = <String, dynamic>{
        'product': productId,
        'quantity': quantity,
      };
      if (variantId != null) {
        data['variant'] = variantId;
      }

      debugPrint('🟢 Adding to cart: ${AppConfig.cartEndpoint}/items/ with data: $data');
      final response = await _dio.post(
        '${AppConfig.cartEndpoint}/items/',
        data: data,
      );
      debugPrint('🟢 Add to cart response status: ${response.statusCode}');
      debugPrint('🟢 Add to cart response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final error = _handleError(e);
      debugPrint('❌ Error adding to cart: $error');
      throw error;
    }
  }

  /// Update cart item quantity
  Future<Map<String, dynamic>> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.patch(
        '${AppConfig.cartEndpoint}/items/$itemId/',
        data: {'quantity': quantity},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(int itemId) async {
    try {
      await _dio.delete('${AppConfig.cartEndpoint}/items/$itemId/delete/');
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
        case 429:
          // Rate limiting / Throttling
          if (data is Map<String, dynamic>) {
            if (data.containsKey('detail')) {
              return data['detail'] as String;
            } else if (data.containsKey('message')) {
              return data['message'] as String;
            }
          }
          return 'Request was throttled. Please try again later.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'An error occurred. Status code: $statusCode';
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. The server is taking too long to respond. Please check your internet connection and try again.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network settings and try again.';
    } else if (error.type == DioExceptionType.sendTimeout) {
      return 'Request timeout. Please check your connection and try again.';
    } else {
      return 'An unexpected error occurred: ${error.message ?? 'Unknown error'}';
    }
  }
}

