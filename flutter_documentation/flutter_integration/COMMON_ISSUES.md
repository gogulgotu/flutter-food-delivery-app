# Common Issues and Troubleshooting

This guide addresses common issues you may encounter when integrating the Django REST Framework API with Flutter.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [Network Issues](#network-issues)
3. [CORS Issues](#cors-issues)
4. [Data Parsing Issues](#data-parsing-issues)
5. [Token Management Issues](#token-management-issues)
6. [File Upload Issues](#file-upload-issues)
7. [Performance Issues](#performance-issues)

---

## Authentication Issues

### Issue: Token Expired (401 Unauthorized)

**Symptoms:**
- API requests return 401 status code
- Error message: "Token is invalid or expired"

**Solution:**
```dart
// Implement automatic token refresh in interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        // Retry original request
        final opts = err.requestOptions;
        final token = await _storage.read(key: 'access_token');
        opts.headers['Authorization'] = 'Bearer $token';
        final response = await Dio().fetch(opts);
        handler.resolve(response);
        return;
      }
    }
    handler.next(err);
  }
}
```

### Issue: Token Not Being Sent

**Symptoms:**
- All authenticated requests return 401
- Token exists in storage but not in request headers

**Solution:**
```dart
// Ensure token is read from secure storage in interceptor
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  final token = await _storage.read(key: 'access_token');
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  handler.next(options);
}
```

### Issue: OTP Not Received

**Symptoms:**
- OTP send request succeeds but OTP not received

**Solution:**
- In development, OTP is returned in API response
- In production, check SMS service configuration
- Verify phone number format: `+919876543210`
- Check OTP expiration (5 minutes)

---

## Network Issues

### Issue: Connection Timeout

**Symptoms:**
- Requests timeout after 30 seconds
- Error: "Connection timeout"

**Solution:**
```dart
// Increase timeout in Dio configuration
BaseOptions(
  connectTimeout: Duration(seconds: 60),
  receiveTimeout: Duration(seconds: 60),
)
```

### Issue: No Internet Connection

**Symptoms:**
- Error: "Network error" or "No internet connection"

**Solution:**
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> checkInternetConnection() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// Check before making requests
if (await checkInternetConnection()) {
  // Make API request
} else {
  // Show offline message
}
```

### Issue: SSL Certificate Error

**Symptoms:**
- Error: "HandshakeException" or "Certificate verify failed"

**Solution (Development only):**
```dart
// Allow insecure connections in development
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = 
  (HttpClient client) {
    client.badCertificateCallback = 
      (X509Certificate cert, String host, int port) => true;
    return client;
  };
```

**Production:**
- Configure proper SSL certificates
- Use certificate pinning

---

## CORS Issues

### Issue: CORS Error in Web/Desktop

**Symptoms:**
- Error: "CORS policy" or "Access-Control-Allow-Origin"

**Solution:**
- CORS is typically configured on the server
- For mobile apps, CORS is not an issue
- For web/desktop, ensure server allows your origin

**Server Configuration (Django):**
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "https://yourdomain.com",
]
```

---

## Data Parsing Issues

### Issue: JSON Decode Error

**Symptoms:**
- Error: "FormatException: Unexpected character"
- Response is not valid JSON

**Solution:**
```dart
// Add error handling
try {
  final response = await apiClient.get('/endpoint/');
  final data = response.data;
  // Process data
} on DioException catch (e) {
  if (e.type == DioExceptionType.badResponse) {
    print('Response data: ${e.response?.data}');
  }
}
```

### Issue: Null Safety Errors

**Symptoms:**
- Error: "Null check operator used on a null value"

**Solution:**
```dart
// Use null-safe operators
final user = User.fromJson(response.data);
final email = user.email ?? 'No email';
final name = user.firstName ?? 'Unknown';

// Or provide defaults in model
class User {
  final String email;
  final String firstName;
  
  User({
    required this.email,
    this.firstName = 'Unknown',
  });
}
```

### Issue: Type Mismatch

**Symptoms:**
- Error: "type 'String' is not a subtype of type 'int'"

**Solution:**
```dart
// Parse data correctly
final price = double.parse(response.data['price'].toString());
final quantity = int.parse(response.data['quantity'].toString());

// Or use type-safe parsing
final price = (response.data['price'] as num).toDouble();
```

---

## Token Management Issues

### Issue: Token Not Persisting

**Symptoms:**
- User logged out after app restart
- Token not found in storage

**Solution:**
```dart
// Use FlutterSecureStorage for tokens
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

// Store token
await storage.write(key: 'access_token', value: token);

// Read token
final token = await storage.read(key: 'access_token');
```

### Issue: Multiple Token Refresh Attempts

**Symptoms:**
- Multiple refresh requests sent simultaneously
- Race condition in token refresh

**Solution:**
```dart
bool _isRefreshing = false;
final _refreshLock = Lock();

Future<bool> refreshToken() async {
  return await _refreshLock.synchronized(() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh
      await Future.delayed(Duration(milliseconds: 100));
      return true;
    }
    
    _isRefreshing = true;
    try {
      // Refresh token logic
      return true;
    } finally {
      _isRefreshing = false;
    }
  });
}
```

---

## File Upload Issues

### Issue: File Upload Fails

**Symptoms:**
- Error: "Multipart form data error"
- File not uploaded

**Solution:**
```dart
// Use FormData for file uploads
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(
    filePath,
    filename: fileName,
  ),
  'other_field': 'value',
});

final response = await dio.post(
  '/upload/',
  data: formData,
  options: Options(
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  ),
);
```

### Issue: Large File Upload Timeout

**Symptoms:**
- Upload times out for large files

**Solution:**
```dart
// Increase timeout for uploads
BaseOptions(
  sendTimeout: Duration(minutes: 5), // For large files
)

// Show upload progress
await dio.post(
  '/upload/',
  data: formData,
  onSendProgress: (sent, total) {
    final progress = (sent / total) * 100;
    print('Upload progress: $progress%');
  },
);
```

---

## Performance Issues

### Issue: Slow API Responses

**Symptoms:**
- API calls take too long
- App feels sluggish

**Solution:**
1. **Implement Caching:**
```dart
class CacheInterceptor extends Interceptor {
  final Map<String, CachedResponse> _cache = {};
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = options.uri.toString();
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (!cached.isExpired) {
        handler.resolve(Response(
          requestOptions: options,
          data: cached.data,
        ));
        return;
      }
    }
    handler.next(options);
  }
}
```

2. **Use Pagination:**
```dart
// Load data in pages
final orders = await orderService.getOrders(page: 1, pageSize: 20);
```

3. **Optimize Requests:**
```dart
// Cancel previous requests
CancelToken cancelToken = CancelToken();

// Make request
await apiClient.get('/endpoint/', cancelToken: cancelToken);

// Cancel if needed
cancelToken.cancel();
```

### Issue: Too Many API Calls

**Symptoms:**
- Multiple duplicate requests
- High network usage

**Solution:**
```dart
// Debounce requests
Timer? _debounceTimer;

void debounceRequest(Function() request, {Duration delay = const Duration(milliseconds: 500)}) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(delay, request);
}

// Usage
debounceRequest(() {
  searchProducts(query);
});
```

---

## Platform-Specific Issues

### Android: Cleartext Traffic

**Symptoms:**
- Error: "Cleartext HTTP traffic not permitted"

**Solution:**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

### iOS: App Transport Security

**Symptoms:**
- Network requests blocked on iOS

**Solution:**
Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## Debugging Tips

### 1. Enable Logging

```dart
// Add logging interceptor
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  error: true,
));
```

### 2. Check Request/Response

```dart
// Log request details
print('Request URL: ${options.uri}');
print('Request Headers: ${options.headers}');
print('Request Data: ${options.data}');

// Log response
print('Response Status: ${response.statusCode}');
print('Response Data: ${response.data}');
```

### 3. Test with Postman

- Import OpenAPI spec to Postman
- Test endpoints independently
- Compare Flutter requests with Postman requests

### 4. Use Network Inspector

- Flutter DevTools Network tab
- Charles Proxy / Fiddler
- Browser DevTools (for web)

---

## Best Practices

1. **Always handle errors** - Don't let exceptions crash the app
2. **Show loading states** - Provide user feedback
3. **Implement retry logic** - For transient failures
4. **Cache data** - Reduce API calls
5. **Validate data** - Before sending to API
6. **Use pagination** - For large datasets
7. **Cancel requests** - When navigating away
8. **Monitor network** - Check connectivity before requests

---

## Getting Help

If you encounter issues not covered here:

1. Check the [API Documentation](../api_documentation/)
2. Review [Request/Response Examples](./REQUEST_RESPONSE_EXAMPLES.md)
3. Check server logs for errors
4. Verify API endpoint is working with Postman/cURL
5. Contact the development team

---

**Common Error Codes:**

- `400` - Bad Request (validation errors)
- `401` - Unauthorized (token expired/invalid)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (resource doesn't exist)
- `500` - Server Error (server-side issue)

