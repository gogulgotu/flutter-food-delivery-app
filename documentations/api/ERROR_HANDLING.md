# Error Handling Guide

## Overview

This guide explains how to handle errors returned by the Hotel Management System API. All error responses follow a consistent format for easy handling in client applications.

## Error Response Format

### Standard Error Response

```json
{
  "error": "Error message",
  "detail": "Detailed error description",
  "code": "ERROR_CODE"
}
```

### Validation Error Response

For validation errors (400 Bad Request), the response includes field-specific errors:

```json
{
  "error": "Validation failed",
  "detail": {
    "email": ["This field is required."],
    "password": ["This field must be at least 8 characters."]
  }
}
```

## HTTP Status Codes

| Status Code | Meaning | Description |
|-------------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request data or validation errors |
| 401 | Unauthorized | Authentication required or token invalid |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 405 | Method Not Allowed | HTTP method not allowed for this endpoint |
| 500 | Internal Server Error | Server error |
| 502 | Bad Gateway | Gateway error |
| 503 | Service Unavailable | Service temporarily unavailable |

## Common Error Scenarios

### 1. Authentication Errors (401)

**Token Missing:**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

**Token Invalid/Expired:**
```json
{
  "detail": "Given token not valid for any token type",
  "code": "token_not_valid",
  "messages": [
    {
      "token_class": "AccessToken",
      "token_type": "access",
      "message": "Token is invalid or expired"
    }
  ]
}
```

**Action:** Refresh the access token or re-authenticate.

### 2. Permission Errors (403)

```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Action:** Check user role and permissions. Some endpoints require specific roles.

### 3. Validation Errors (400)

**Missing Required Fields:**
```json
{
  "error": "Validation failed",
  "detail": {
    "email": ["This field is required."],
    "password": ["This field is required."]
  }
}
```

**Invalid Data Format:**
```json
{
  "error": "Invalid data",
  "detail": {
    "email": ["Enter a valid email address."],
    "phone_number": ["Enter a valid phone number."]
  }
}
```

**Action:** Validate data before sending and display field-specific errors to users.

### 4. Not Found Errors (404)

**Resource Not Found:**
```json
{
  "detail": "Not found."
}
```

**Specific Resource:**
```json
{
  "error": "Order not found"
}
```

**Action:** Check if the resource ID exists and user has access to it.

### 5. Server Errors (500)

```json
{
  "error": "Internal server error",
  "detail": "An unexpected error occurred. Please try again later."
}
```

**Action:** Log the error, show user-friendly message, and retry if appropriate.

## Error Handling in Flutter

### Basic Error Handling

```dart
try {
  final response = await dio.get('/api/users/profile/');
  // Handle success
} on DioException catch (e) {
  if (e.response != null) {
    // Server responded with error
    final statusCode = e.response!.statusCode;
    final errorData = e.response!.data;
    
    switch (statusCode) {
      case 400:
        // Handle validation errors
        break;
      case 401:
        // Handle authentication error
        break;
      case 403:
        // Handle permission error
        break;
      case 404:
        // Handle not found
        break;
      case 500:
        // Handle server error
        break;
    }
  } else {
    // Network error
    print('Network error: ${e.message}');
  }
}
```

### Error Model Class

```dart
class ApiError {
  final String? error;
  final String? detail;
  final String? code;
  final Map<String, dynamic>? fieldErrors;

  ApiError({
    this.error,
    this.detail,
    this.code,
    this.fieldErrors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      error: json['error'] as String?,
      detail: json['detail'] is String 
          ? json['detail'] as String?
          : null,
      code: json['code'] as String?,
      fieldErrors: json['detail'] is Map 
          ? json['detail'] as Map<String, dynamic>?
          : null,
    );
  }

  String get message {
    if (error != null) return error!;
    if (detail is String) return detail as String;
    return 'An error occurred';
  }
}
```

### Error Handler Utility

```dart
class ErrorHandler {
  static String getErrorMessage(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      try {
        final apiError = ApiError.fromJson(data);
        
        // Handle field-specific errors
        if (apiError.fieldErrors != null) {
          final firstError = apiError.fieldErrors!.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
        
        return apiError.message;
      } catch (e) {
        // Fallback to status code message
        return _getDefaultMessage(statusCode!);
      }
    } else {
      // Network error
      return 'Network error. Please check your connection.';
    }
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
```

## Specific Error Cases

### Order Errors

**Order Already Paid:**
```json
{
  "error": "Order is already paid."
}
```

**Insufficient Stock:**
```json
{
  "error": "Insufficient stock for product: Pizza"
}
```

**Order Not Found:**
```json
{
  "error": "Order not found"
}
```

### Payment Errors

**Payment Gateway Not Configured:**
```json
{
  "error": "Paytm credentials not found. Online payments will be disabled until credentials are configured."
}
```

**Payment Verification Failed:**
```json
{
  "error": "Invalid payment signature"
}
```

**Payment Failed:**
```json
{
  "status": "failed",
  "error": "Payment failed"
}
```

### Cart Errors

**Product Not Available:**
```json
{
  "error": "Product is not available"
}
```

**Invalid Quantity:**
```json
{
  "error": "Quantity must be greater than 0"
}
```

### User Errors

**User Already Exists:**
```json
{
  "error": "User with this email already exists"
}
```

**Invalid Credentials:**
```json
{
  "error": "Invalid email or password"
}
```

**OTP Errors:**
```json
{
  "error": "Invalid OTP"
}
```

```json
{
  "error": "OTP expired"
}
```

```json
{
  "error": "Too many failed attempts"
}
```

## Best Practices

1. **Always check status codes** before processing response data
2. **Handle network errors** separately from API errors
3. **Show user-friendly messages** - Don't expose technical details
4. **Log errors** for debugging purposes
5. **Implement retry logic** for transient errors (500, 502, 503)
6. **Validate data client-side** to reduce validation errors
7. **Handle token expiration** gracefully with automatic refresh
8. **Display field-specific errors** for better UX

## Error Recovery Strategies

### Automatic Retry

```dart
Future<Response> retryRequest(
  Future<Response> Function() request, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  int attempts = 0;
  
  while (attempts < maxRetries) {
    try {
      return await request();
    } on DioException catch (e) {
      attempts++;
      
      // Don't retry on client errors (4xx)
      if (e.response?.statusCode != null && 
          e.response!.statusCode! >= 400 && 
          e.response!.statusCode! < 500) {
        rethrow;
      }
      
      // Retry on server errors (5xx) or network errors
      if (attempts < maxRetries) {
        await Future.delayed(delay * attempts);
        continue;
      }
      
      rethrow;
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

### Token Refresh on 401

```dart
Future<Response> makeAuthenticatedRequest(
  Future<Response> Function() request,
) async {
  try {
    return await request();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        // Retry original request
        return await request();
      } else {
        // Redirect to login
        throw AuthenticationException('Please login again');
      }
    }
    rethrow;
  }
}
```

## Testing Error Handling

### Test Cases

1. **Invalid credentials** - Should return 401
2. **Missing required fields** - Should return 400 with field errors
3. **Invalid data format** - Should return 400
4. **Non-existent resource** - Should return 404
5. **Insufficient permissions** - Should return 403
6. **Network timeout** - Should handle gracefully
7. **Server error** - Should show user-friendly message

---

**Next Steps:**
- Review [ENDPOINTS.md](./ENDPOINTS.md) for endpoint-specific error responses
- Check [Flutter Integration Guide](../flutter_integration/COMMON_ISSUES.md) for Flutter-specific error handling

