# API Overview

## Introduction

The Hotel Management System API is a comprehensive RESTful API built with Django REST Framework. It provides endpoints for managing hotels, orders, payments, deliveries, and user interactions.

## Base URL

### Development
```
http://localhost:8000/api
```

### Production
```
https://your-domain.com/api
```

## API Version

Current API Version: **v1**

All endpoints are accessed through the `/api/` prefix.

## Content Type

The API uses **JSON** for request and response bodies.

**Request Headers:**
```
Content-Type: application/json
Accept: application/json
```

## Authentication

The API uses **JWT (JSON Web Tokens)** for authentication. Most endpoints require authentication except for:
- User registration
- OTP sending/verification
- Public vendor/product listings
- Test endpoints

See [AUTHENTICATION.md](./AUTHENTICATION.md) for detailed authentication information.

## Response Format

### Success Response

All successful responses follow this structure:

```json
{
  "status": "success",
  "data": { ... },
  "message": "Optional success message"
}
```

### Error Response

Error responses follow this structure:

```json
{
  "error": "Error message",
  "detail": "Detailed error description",
  "code": "ERROR_CODE"
}
```

See [ERROR_HANDLING.md](./ERROR_HANDLING.md) for detailed error handling information.

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid request data |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 500 | Internal Server Error - Server error |

## Rate Limiting

Currently, the API does not enforce strict rate limiting, but it's recommended to:
- Implement client-side rate limiting
- Cache responses when appropriate
- Use pagination for large datasets

## Pagination

List endpoints support pagination using query parameters:

```
GET /api/vendors/?page=1&page_size=20
```

Response format:
```json
{
  "count": 100,
  "next": "http://api.example.com/api/vendors/?page=2",
  "previous": null,
  "results": [ ... ]
}
```

## Filtering

Many list endpoints support filtering:

```
GET /api/products/?category=fast-food&min_price=100&max_price=500
```

## Search

Search functionality is available on relevant endpoints:

```
GET /api/search/?q=pizza&type=product
```

## File Uploads

For file uploads (images, documents), use `multipart/form-data`:

```
Content-Type: multipart/form-data
```

## WebSocket Support

The API supports WebSocket connections for real-time updates:

```
ws://your-domain.com/ws/orders/
```

WebSocket authentication uses the same JWT tokens.

## API Endpoints Overview

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - JWT token login
- `POST /api/auth/login-user/` - User login with credentials
- `POST /api/auth/send-otp/` - Send OTP to mobile number
- `POST /api/auth/verify-otp/` - Verify OTP and get tokens
- `POST /api/auth/token/refresh/` - Refresh JWT token

### Users
- `GET /api/users/profile/` - Get user profile
- `PATCH /api/users/profile/update/` - Update user profile
- `GET /api/users/delivery-profile/` - Get delivery person profile
- `GET /api/users/hotel-owner-profile/` - Get hotel owner profile

### Addresses
- `GET /api/addresses/` - List user addresses
- `POST /api/addresses/` - Create new address
- `GET /api/addresses/{id}/` - Get address details
- `PATCH /api/addresses/{id}/` - Update address
- `DELETE /api/addresses/{id}/` - Delete address

### Vendors
- `GET /api/vendors/` - List vendors
- `GET /api/vendors/{slug}/` - Get vendor details
- `GET /api/vendor-categories/` - List vendor categories

### Products
- `GET /api/products/` - List products
- `GET /api/products/{slug}/` - Get product details
- `GET /api/product-categories/` - List product categories

### Cart
- `GET /api/cart/` - Get user cart
- `POST /api/cart/items/` - Add item to cart
- `PATCH /api/cart/items/{id}/` - Update cart item
- `DELETE /api/cart/items/{id}/` - Remove cart item

### Orders
- `GET /api/orders/` - List user orders
- `POST /api/orders/` - Create new order
- `GET /api/orders/{id}/` - Get order details
- `POST /api/orders/{id}/review/` - Create order review
- `POST /api/orders/{id}/cancel/` - Cancel order

### Payments
- `GET /api/payments/` - List payments
- `GET /api/payments/{id}/` - Get payment details
- `POST /api/payments/paytm/create-order/` - Create Paytm payment order
- `POST /api/payments/paytm/verify/` - Verify Paytm payment

### Wallet
- `GET /api/wallet/` - Get wallet balance
- `GET /api/wallet/transactions/` - List wallet transactions

### Notifications
- `GET /api/notifications/` - List notifications
- `GET /api/notifications/{id}/` - Get notification details
- `POST /api/notifications/mark-all-read/` - Mark all as read

### Delivery
- `GET /api/delivery/dashboard/` - Delivery person dashboard
- `GET /api/delivery/assignments/` - List delivery assignments
- `POST /api/delivery/toggle-online/` - Toggle online status

### Dashboard (Hotel Owner)
- `GET /api/dashboard/home/` - Dashboard home stats
- `GET /api/dashboard/orders/` - Dashboard orders
- `GET /api/dashboard/menu/` - Menu items
- `GET /api/dashboard/analytics/metrics/` - Analytics metrics

## Data Models

### User
- `id` (UUID)
- `email` (String)
- `phone_number` (String)
- `first_name` (String)
- `last_name` (String)
- `user_role` (String) - customer, delivery_person, hotel_owner, admin

### Order
- `id` (UUID)
- `order_number` (String)
- `user` (UUID)
- `vendor` (UUID)
- `total_amount` (Decimal)
- `payment_status` (String)
- `order_status` (String)
- `delivery_status` (String)

### Product
- `id` (UUID)
- `name` (String)
- `description` (Text)
- `price` (Decimal)
- `vendor` (UUID)
- `category` (UUID)

## Best Practices

1. **Always include Authorization header** for authenticated requests
2. **Handle errors gracefully** - Check status codes and error messages
3. **Implement retry logic** for network failures
4. **Cache data** when appropriate to reduce API calls
5. **Use pagination** for large datasets
6. **Validate data** before sending requests
7. **Store tokens securely** using secure storage
8. **Refresh tokens** before they expire

## Testing

You can test the API using:
- **Swagger UI** - Interactive API documentation
- **Postman** - Import the OpenAPI specification
- **cURL** - Command-line tool
- **Flutter HTTP client** - Direct integration

## Support

For API support:
1. Check the [ERROR_HANDLING.md](./ERROR_HANDLING.md) guide
2. Review endpoint-specific documentation in [ENDPOINTS.md](./ENDPOINTS.md)
3. Contact the development team

---

**Next Steps:**
- Read [AUTHENTICATION.md](./AUTHENTICATION.md) for authentication setup
- Review [ENDPOINTS.md](./ENDPOINTS.md) for detailed endpoint documentation
- Check [Flutter Integration Guide](../flutter_integration/SETUP_GUIDE.md) for Flutter setup

