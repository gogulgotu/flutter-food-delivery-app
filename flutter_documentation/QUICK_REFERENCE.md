# Quick Reference Guide

A quick reference for common API operations in Flutter.

## Base Configuration

```dart
// API Base URL
const String API_BASE_URL = 'http://localhost:8000/api';

// Headers
final headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer $accessToken',
};
```

## Authentication

### Login
```dart
POST /api/auth/login/
Body: {"email": "user@example.com", "password": "password"}
Response: {"access": "token", "refresh": "token", "user": {...}}
```

### Send OTP
```dart
POST /api/auth/send-otp/
Body: {"mobile_number": "+919876543210"}
Response: {"message": "OTP sent", "otp": "123456"}
```

### Verify OTP
```dart
POST /api/auth/verify-otp/
Body: {"mobile_number": "+919876543210", "otp": "123456"}
Response: {"tokens": {"access": "...", "refresh": "..."}, "user": {...}}
```

## Common Endpoints

### Get User Profile
```dart
GET /api/users/profile/
Headers: Authorization: Bearer <token>
```

### List Vendors
```dart
GET /api/vendors/?category=fast-food&page=1
```

### Get Products
```dart
GET /api/products/?vendor=vendor-uuid&is_available=true
```

### Get Cart
```dart
GET /api/cart/?vendor=vendor-uuid
Headers: Authorization: Bearer <token>
```

### Create Order
```dart
POST /api/orders/
Headers: Authorization: Bearer <token>
Body: {
  "vendor": "uuid",
  "delivery_address": 1,
  "items": [...],
  "total_amount": 500.00,
  "payment_method": "cod"
}
```

## Error Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (token expired)
- `403` - Forbidden (no permission)
- `404` - Not Found
- `500` - Server Error

## Common Patterns

### Making Authenticated Request
```dart
final response = await dio.get(
  '/api/users/profile/',
  options: Options(
    headers: {'Authorization': 'Bearer $token'},
  ),
);
```

### Handling Errors
```dart
try {
  final response = await apiClient.get('/endpoint/');
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Refresh token
  } else {
    // Handle other errors
  }
}
```

### Pagination
```dart
GET /api/vendors/?page=1&page_size=20
Response: {
  "count": 100,
  "next": "...",
  "previous": null,
  "results": [...]
}
```

---

For detailed documentation, see:
- [API Overview](./api_documentation/API_OVERVIEW.md)
- [Endpoints](./api_documentation/ENDPOINTS.md)
- [Flutter Integration](./flutter_integration/SETUP_GUIDE.md)

