# Authentication Guide

## Overview

The Hotel Management System API uses **JWT (JSON Web Tokens)** for authentication. JWT tokens provide a secure, stateless way to authenticate API requests.

## Authentication Methods

### 1. JWT Token Authentication (Standard)

JWT tokens are obtained through login endpoints and must be included in the `Authorization` header for authenticated requests.

### 2. OTP-based Authentication (Mobile)

For mobile applications, the API supports OTP (One-Time Password) based authentication using mobile numbers.

## Getting JWT Tokens

### Method 1: Standard Login

**Endpoint:** `POST /api/auth/login/`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

### Method 2: User Login (Alternative)

**Endpoint:** `POST /api/auth/login-user/`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "user_role_name": "Customer"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
}
```

### Method 3: OTP-based Authentication

#### Step 1: Send OTP

**Endpoint:** `POST /api/auth/send-otp/`

**Request:**
```json
{
  "mobile_number": "+919876543210"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "otp_sent": true
}
```

#### Step 2: Verify OTP

**Endpoint:** `POST /api/auth/verify-otp/`

**Request:**
```json
{
  "mobile_number": "+919876543210",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "phone_number": "+919876543210",
    "user_role_name": "Customer"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  },
  "user_type": "existing"
}
```

## Using JWT Tokens

### Access Token

The **access token** is used for authenticating API requests. It has a limited lifetime (typically 15 minutes to 1 hour).

**Header Format:**
```
Authorization: Bearer <access_token>
```

**Example:**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Refresh Token

The **refresh token** is used to obtain a new access token when it expires. Refresh tokens have a longer lifetime (typically 7-15 days).

**Endpoint:** `POST /api/auth/token/refresh/`

**Request:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

## Token Expiration

### Access Token
- **Lifetime:** 15 minutes (configurable)
- **Expiration:** Token expires after the set time
- **Response:** 401 Unauthorized when expired

### Refresh Token
- **Lifetime:** 7-15 days (configurable)
- **Expiration:** Token expires after the set time
- **Action:** User must login again when refresh token expires

## Token Claims

JWT tokens contain the following claims:

```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "role": "customer",
  "is_verified": true,
  "exp": 1234567890,
  "iat": 1234567890
}
```

## Making Authenticated Requests

### Example: Get User Profile

```http
GET /api/users/profile/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json
```

### Example: Create Order

```http
POST /api/orders/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json

{
  "vendor": "vendor-uuid",
  "delivery_address": "address-uuid",
  "items": [...],
  "total_amount": 500.00
}
```

## Handling Token Expiration

### Automatic Token Refresh

When a request returns `401 Unauthorized`, you should:

1. Attempt to refresh the token using the refresh token
2. Retry the original request with the new access token
3. If refresh fails, redirect user to login

### Example Flow

```dart
// Pseudo-code
try {
  response = await api.get('/api/users/profile/');
} catch (e) {
  if (e.statusCode == 401) {
    // Token expired, refresh it
    newAccessToken = await refreshToken();
    // Retry request
    response = await api.get('/api/users/profile/');
  }
}
```

## User Registration

**Endpoint:** `POST /api/auth/register/`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+919876543210"
}
```

**Response:**
```json
{
  "message": "User registered successfully. Please verify your phone number with OTP to complete registration.",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "requires_otp_verification": true
}
```

**Note:** After registration, users need to verify their phone number with OTP to get access tokens.

## Role-Based Access Control

The API supports different user roles:

- **customer** - Regular users who can place orders
- **delivery_person** - Delivery personnel
- **hotel_owner** - Restaurant/hotel owners
- **admin** - System administrators

Different endpoints may require specific roles. Check endpoint documentation for role requirements.

## Security Best Practices

1. **Store tokens securely**
   - Use secure storage (not plain text)
   - Use `flutter_secure_storage` or similar
   - Never commit tokens to version control

2. **Handle token expiration**
   - Implement automatic token refresh
   - Handle refresh failures gracefully
   - Clear tokens on logout

3. **Use HTTPS**
   - Always use HTTPS in production
   - Never send tokens over unencrypted connections

4. **Validate tokens**
   - Check token expiration before making requests
   - Refresh tokens proactively (before expiration)

5. **Logout properly**
   - Clear tokens from storage
   - Invalidate refresh tokens on server (if supported)

## Error Responses

### 401 Unauthorized

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

### 403 Forbidden

```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Action:** User doesn't have required permissions for this endpoint.

## Flutter Implementation

See [AUTHENTICATION_EXAMPLE.dart](../flutter_integration/AUTHENTICATION_EXAMPLE.dart) for a complete Flutter implementation example.

## Testing Authentication

### Using cURL

```bash
# Login
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Use token
curl -X GET http://localhost:8000/api/users/profile/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Using Postman

1. Create a new request
2. Set method to POST
3. URL: `http://localhost:8000/api/auth/login/`
4. Body (raw JSON): `{"email":"user@example.com","password":"password123"}`
5. Send request
6. Copy the `access` token from response
7. For authenticated requests, add header: `Authorization: Bearer <token>`

---

**Next Steps:**
- Review [ENDPOINTS.md](./ENDPOINTS.md) for endpoint-specific authentication requirements
- Check [Flutter Authentication Example](../flutter_integration/AUTHENTICATION_EXAMPLE.dart) for implementation

