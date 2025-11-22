# Throttling Error Solution Guide

## Understanding Throttling

Throttling (rate limiting) is a mechanism that limits the number of API requests a client can make within a specific time period. This prevents API abuse and ensures fair usage.

**Common Causes:**
- Too many requests in a short time
- Rapid retry attempts
- Multiple simultaneous requests
- Backend rate limiting configuration

## Solutions

### 1. Django Backend Configuration

#### Option A: Disable Throttling (Development Only)

If you're in development and want to disable throttling temporarily:

```python
# settings.py

# Remove or comment out throttling classes
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        # 'rest_framework.throttling.AnonRateThrottle',
        # 'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        # 'anon': '100/hour',
        # 'user': '1000/hour',
    }
}
```

#### Option B: Increase Throttle Limits

Increase the allowed requests per time period:

```python
# settings.py

REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '1000/hour',      # Increased from default
        'user': '10000/hour',     # Increased from default
    }
}
```

#### Option C: Configure Per-View Throttling

Set different limits for specific endpoints:

```python
# views.py or viewsets.py

from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from rest_framework.viewsets import ModelViewSet

class CustomUserThrottle(UserRateThrottle):
    rate = '1000/hour'  # Custom rate

class VendorViewSet(ModelViewSet):
    throttle_classes = [CustomUserThrottle]
    # ... rest of your viewset
```

#### Option D: Exclude Public Endpoints from Throttling

For public endpoints like vendors and products:

```python
# views.py

from rest_framework.throttling import AnonRateThrottle

class VendorViewSet(ModelViewSet):
    throttle_classes = []  # No throttling for public endpoints
    # OR
    throttle_classes = [AnonRateThrottle]  # Very high limit
    throttle_scope = 'vendors'  # Custom scope

# settings.py
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_RATES': {
        'vendors': '10000/hour',  # High limit for vendors
        'products': '10000/hour',  # High limit for products
    }
}
```

### 2. Flutter Frontend Solutions

#### A. Implement Request Debouncing

Prevent multiple rapid requests:

```dart
// In your provider
Timer? _debounceTimer;

void loadVendors({bool reset = false}) async {
  // Cancel previous timer
  _debounceTimer?.cancel();
  
  // Wait 500ms before making request
  _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
    // Make actual API call
    // ... your existing code
  });
}
```

#### B. Add Request Caching

Cache responses to reduce API calls:

```dart
// In your provider
DateTime? _lastVendorsFetch;
Duration _cacheDuration = const Duration(minutes: 5);

Future<void> loadVendors({bool reset = false}) async {
  // Check cache
  if (!reset && _lastVendorsFetch != null) {
    final timeSinceLastFetch = DateTime.now().difference(_lastVendorsFetch!);
    if (timeSinceLastFetch < _cacheDuration && _vendors.isNotEmpty) {
      return; // Use cached data
    }
  }
  
  // Make API call
  // ... your existing code
  
  _lastVendorsFetch = DateTime.now();
}
```

#### C. Implement Exponential Backoff for Retries

When throttled, wait before retrying:

```dart
// In your provider
int _retryAttempt = 0;
const int _maxRetries = 3;

Future<void> loadVendors({bool reset = false}) async {
  if (reset) {
    _retryAttempt = 0;
  }
  
  try {
    // ... API call
    _retryAttempt = 0; // Reset on success
  } catch (e) {
    if (ErrorUtils.isThrottlingError(e.toString()) && _retryAttempt < _maxRetries) {
      _retryAttempt++;
      final waitTime = Duration(seconds: pow(2, _retryAttempt).toInt()); // Exponential backoff
      await Future.delayed(waitTime);
      return loadVendors(reset: reset);
    }
    // Handle error
  }
}
```

#### D. Batch Requests

Combine multiple requests into one:

```dart
// Instead of separate calls
await loadVendors();
await loadProducts();
await loadCategories();

// Use a single endpoint that returns all data
await loadCatalog(); // Already implemented
```

### 3. Immediate Fixes

#### Quick Fix 1: Increase Time Between Requests

```dart
// In catalog_provider.dart
Future<void> loadVendors({bool reset = false}) async {
  // Add delay between requests
  if (!reset && _vendors.isNotEmpty) {
    await Future.delayed(const Duration(seconds: 1));
  }
  // ... rest of code
}
```

#### Quick Fix 2: Reduce Request Frequency

```dart
// Only load when necessary
bool _isLoading = false;

Future<void> loadVendors({bool reset = false}) async {
  if (_isLoading) return; // Prevent concurrent requests
  _isLoading = true;
  try {
    // ... API call
  } finally {
    _isLoading = false;
  }
}
```

#### Quick Fix 3: Use Pagination Wisely

```dart
// Load fewer items per page
final int _vendorsPageSize = 10; // Reduced from 20

// Only load next page when user scrolls near bottom
void _onScroll() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent * 0.9) { // Changed from 0.8
    // Load more
  }
}
```

### 4. Best Practices

#### A. Request Optimization
- ✅ Cache responses locally
- ✅ Use pagination effectively
- ✅ Load data only when needed
- ✅ Debounce search queries
- ✅ Batch related requests

#### B. Error Handling
- ✅ Show user-friendly error messages
- ✅ Implement exponential backoff
- ✅ Disable retry button during throttling
- ✅ Display retry time clearly

#### C. User Experience
- ✅ Show loading states
- ✅ Display cached data while refreshing
- ✅ Provide clear feedback on errors
- ✅ Allow manual refresh

## Recommended Configuration

### For Development:

```python
# Django settings.py
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '1000/hour',  # High limit for development
        'user': '10000/hour',
    }
}
```

### For Production:

```python
# Django settings.py
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',   # Reasonable for anonymous users
        'user': '1000/hour',  # Higher for authenticated users
    }
}

# Exclude public catalog endpoints
# In your viewsets:
class VendorViewSet(ModelViewSet):
    throttle_classes = []  # No throttling for public catalog
```

## Testing Your Fix

1. **Check Current Throttle Settings:**
   ```bash
   # In Django shell
   python manage.py shell
   >>> from django.conf import settings
   >>> print(settings.REST_FRAMEWORK.get('DEFAULT_THROTTLE_RATES', {}))
   ```

2. **Test API Endpoints:**
   ```bash
   # Make multiple requests
   for i in {1..10}; do curl http://localhost:8000/api/vendors/; done
   ```

3. **Monitor Throttle Headers:**
   ```bash
   curl -I http://localhost:8000/api/vendors/
   # Look for: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
   ```

## Quick Solution Checklist

- [ ] Check Django REST_FRAMEWORK settings
- [ ] Increase throttle rates or disable for development
- [ ] Exclude public endpoints (vendors/products) from throttling
- [ ] Implement request caching in Flutter
- [ ] Add debouncing to prevent rapid requests
- [ ] Use exponential backoff for retries
- [ ] Reduce request frequency
- [ ] Test with actual API calls

## Emergency Fix (Immediate)

If you need to fix this immediately:

1. **Django Backend:** Disable throttling temporarily
2. **Flutter:** Add request delays and caching
3. **Test:** Verify requests work without throttling
4. **Re-enable:** Configure proper throttling limits

