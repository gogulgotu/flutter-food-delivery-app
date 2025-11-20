# HTTP Client Setup with Dio

## Overview

This guide shows how to set up Dio HTTP client for making API requests to the Django REST Framework backend.

## Why Dio?

Dio is a powerful HTTP client for Dart/Flutter that provides:
- Interceptors for request/response handling
- Automatic request/response serialization
- Request cancellation
- File upload/download
- Timeout configuration
- Error handling

## Step 1: Create API Client

Create `lib/core/api/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  late Dio _dio;
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add interceptors
    _dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(),
      ErrorInterceptor(),
    ]);
  }
  
  Dio get dio => _dio;
  
  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?data,
      });
      
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Error handling
  dynamic _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
      return ApiException(
        message: error.response?.data['error'] ?? 
                 error.response?.data['detail'] ?? 
                 'An error occurred',
        statusCode: error.response?.statusCode,
        data: error.response?.data,
      );
    } else {
      // Network error
      return ApiException(
        message: error.message ?? 'Network error',
        statusCode: null,
      );
    }
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });
  
  @override
  String toString() => message;
}
```

## Step 2: Create Auth Interceptor

Create `lib/core/api/interceptors/auth_interceptor.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get access token from secure storage
    final token = await _storage.read(key: 'access_token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      try {
        // Try to refresh token
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry original request
          final opts = err.requestOptions;
          final token = await _storage.read(key: 'access_token');
          opts.headers['Authorization'] = 'Bearer $token';
          
          final response = await Dio().fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Refresh failed, clear tokens and redirect to login
        await _clearTokens();
        handler.reject(err);
        return;
      }
    }
    
    handler.next(err);
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final dio = Dio();
      final response = await dio.post(
        '${AppConfig.apiBaseUrl}/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await _storage.write(key: 'access_token', value: newAccessToken);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
```

## Step 3: Create Error Interceptor

Create `lib/core/api/interceptors/error_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Transform error response to user-friendly message
    String errorMessage = 'An error occurred';
    
    if (err.response != null) {
      final data = err.response?.data;
      
      if (data is Map<String, dynamic>) {
        // Check for error message
        if (data.containsKey('error')) {
          errorMessage = data['error'];
        } else if (data.containsKey('detail')) {
          if (data['detail'] is String) {
            errorMessage = data['detail'];
          } else if (data['detail'] is Map) {
            // Handle validation errors
            final firstError = data['detail'].values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            }
          }
        }
      }
    } else {
      // Network error
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (err.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        errorMessage = err.message ?? 'Network error';
      }
    }
    
    // Create custom error
    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
    );
    
    handler.next(customError);
  }
}
```

## Step 4: Create Logging Interceptor

Create `lib/core/api/interceptors/logging_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.isDevelopment) {
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers: ${options.headers}');
      if (options.data != null) {
        print('Data: ${options.data}');
      }
    }
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.isDevelopment) {
      print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      print('Data: ${response.data}');
    }
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.isDevelopment) {
      print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('Error: ${err.message}');
      if (err.response != null) {
        print('Response: ${err.response?.data}');
      }
    }
    handler.next(err);
  }
}
```

## Step 5: Usage Example

```dart
import 'package:your_app/core/api/api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  
  Future<User> getUserProfile() async {
    try {
      final response = await _apiClient.get('/users/profile/');
      return User.fromJson(response.data);
    } on ApiException catch (e) {
      throw e;
    }
  }
  
  Future<List<Order>> getOrders() async {
    try {
      final response = await _apiClient.get('/orders/');
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Order.fromJson(json)).toList();
    } on ApiException catch (e) {
      throw e;
    }
  }
}
```

## Configuration Options

### Timeout Configuration

```dart
BaseOptions(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 30),
)
```

### Retry Configuration

Add retry interceptor:

```dart
import 'package:dio/retry.dart';

_dio.interceptors.add(
  RetryInterceptor(
    dio: _dio,
    options: RetryOptions(
      retries: 3,
      retryInterval: Duration(seconds: 2),
    ),
  ),
);
```

### SSL Certificate Pinning (Production)

```dart
import 'package:dio_certificate_pinning/dio_certificate_pinning.dart';

_dio.interceptors.add(
  CertificatePinningInterceptor(
    allowedSHAFingerprints: ['your-certificate-fingerprint'],
  ),
);
```

## Best Practices

1. **Use singleton pattern** for ApiClient
2. **Handle errors consistently** across the app
3. **Implement token refresh** automatically
4. **Log requests/responses** in development only
5. **Use interceptors** for cross-cutting concerns
6. **Cancel requests** when navigating away
7. **Handle network connectivity** before making requests

## Next Steps

- See [API_SERVICE_EXAMPLE.dart](./API_SERVICE_EXAMPLE.dart) for complete service implementation
- Check [AUTHENTICATION_EXAMPLE.dart](./AUTHENTICATION_EXAMPLE.dart) for auth flow

