# API Endpoints Documentation

## Table of Contents

1. [Authentication Endpoints](#authentication-endpoints)
2. [User Endpoints](#user-endpoints)
3. [Address Endpoints](#address-endpoints)
4. [Vendor Endpoints](#vendor-endpoints)
5. [Product Endpoints](#product-endpoints)
6. [Cart Endpoints](#cart-endpoints)
7. [Order Endpoints](#order-endpoints)
8. [Payment Endpoints](#payment-endpoints)
9. [Wallet Endpoints](#wallet-endpoints)
10. [Notification Endpoints](#notification-endpoints)
11. [Delivery Endpoints](#delivery-endpoints)
12. [Dashboard Endpoints](#dashboard-endpoints)
13. [Utility Endpoints](#utility-endpoints)

---

## Authentication Endpoints

### Register User

**Endpoint:** `POST /api/auth/register/`

**Description:** Register a new user account.

**Authentication:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+919876543210"
}
```

**Response (201 Created):**
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

### Login (JWT)

**Endpoint:** `POST /api/auth/login/`

**Description:** Login with email and password to get JWT tokens.

**Authentication:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
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

### Send OTP

**Endpoint:** `POST /api/auth/send-otp/`

**Description:** Send OTP to mobile number for authentication.

**Authentication:** Not required

**Request Body:**
```json
{
  "mobile_number": "+919876543210"
}
```

**Response (200 OK):**
```json
{
  "message": "OTP sent successfully",
  "otp": "123456",
  "expires_in": 300
}
```

**Note:** In production, OTP is sent via SMS. In development, it's returned in response.

### Verify OTP

**Endpoint:** `POST /api/auth/verify-otp/`

**Description:** Verify OTP and get JWT tokens.

**Authentication:** Not required

**Request Body:**
```json
{
  "mobile_number": "+919876543210",
  "otp": "123456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
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

### Refresh Token

**Endpoint:** `POST /api/auth/token/refresh/`

**Description:** Get new access token using refresh token.

**Authentication:** Not required (but refresh token needed)

**Request Body:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

---

## User Endpoints

### Get User Profile

**Endpoint:** `GET /api/users/profile/`

**Description:** Get current user's profile information.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+919876543210",
  "user_role_name": "Customer",
  "is_verified": true
}
```

### Update User Profile

**Endpoint:** `PATCH /api/users/profile/update/`

**Description:** Update user profile information.

**Authentication:** Required

**Request Body:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "newemail@example.com"
}
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "newemail@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
```

---

## Address Endpoints

### List Addresses

**Endpoint:** `GET /api/addresses/`

**Description:** Get list of user's delivery addresses.

**Authentication:** Required

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Home",
    "address_line_1": "123 Main St",
    "address_line_2": "Apt 4B",
    "city": "Mumbai",
    "state": "Maharashtra",
    "country": "India",
    "postal_code": "400001",
    "is_default": true,
    "latitude": 19.0760,
    "longitude": 72.8777
  }
]
```

### Create Address

**Endpoint:** `POST /api/addresses/`

**Description:** Create a new delivery address.

**Authentication:** Required

**Request Body:**
```json
{
  "title": "Home",
  "address_line_1": "123 Main St",
  "address_line_2": "Apt 4B",
  "city": "Mumbai",
  "state": "Maharashtra",
  "country": "India",
  "postal_code": "400001",
  "is_default": false,
  "latitude": 19.0760,
  "longitude": 72.8777
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "title": "Home",
  "address_line_1": "123 Main St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "postal_code": "400001"
}
```

### Get Address Details

**Endpoint:** `GET /api/addresses/{id}/`

**Description:** Get specific address details.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "id": 1,
  "title": "Home",
  "address_line_1": "123 Main St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "postal_code": "400001"
}
```

### Update Address

**Endpoint:** `PATCH /api/addresses/{id}/`

**Description:** Update an existing address.

**Authentication:** Required

**Request Body:**
```json
{
  "title": "Work",
  "address_line_1": "456 Business Ave"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "title": "Work",
  "address_line_1": "456 Business Ave"
}
```

### Delete Address

**Endpoint:** `DELETE /api/addresses/{id}/`

**Description:** Delete an address.

**Authentication:** Required

**Response (204 No Content)**

---

## Vendor Endpoints

### List Vendors

**Endpoint:** `GET /api/vendors/`

**Description:** Get list of vendors (restaurants/hotels).

**Authentication:** Not required (public)

**Query Parameters:**
- `category` - Filter by category slug
- `search` - Search by name
- `page` - Page number
- `page_size` - Items per page

**Response (200 OK):**
```json
{
  "count": 50,
  "next": "http://api.example.com/api/vendors/?page=2",
  "previous": null,
  "results": [
    {
      "id": "uuid",
      "name": "Pizza Palace",
      "slug": "pizza-palace",
      "description": "Best pizza in town",
      "rating": 4.5,
      "delivery_time": 30,
      "delivery_fee": 25.00,
      "minimum_order": 100.00,
      "is_active": true,
      "image": "https://example.com/image.jpg"
    }
  ]
}
```

### Get Vendor Details

**Endpoint:** `GET /api/vendors/{slug}/`

**Description:** Get detailed information about a vendor.

**Authentication:** Not required (public)

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Pizza Palace",
  "slug": "pizza-palace",
  "description": "Best pizza in town",
  "rating": 4.5,
  "delivery_time": 30,
  "delivery_fee": 25.00,
  "minimum_order": 100.00,
  "address": "123 Food Street",
  "phone": "+919876543210",
  "cuisine_types": ["Italian", "Fast Food"],
  "operating_hours": {
    "monday": {"open": "09:00", "close": "22:00"},
    "tuesday": {"open": "09:00", "close": "22:00"}
  }
}
```

---

## Product Endpoints

### List Products

**Endpoint:** `GET /api/products/`

**Description:** Get list of products.

**Authentication:** Not required (public)

**Query Parameters:**
- `vendor` - Filter by vendor ID or slug
- `category` - Filter by category
- `search` - Search products
- `min_price` - Minimum price
- `max_price` - Maximum price
- `is_available` - Filter by availability

**Response (200 OK):**
```json
{
  "count": 100,
  "results": [
    {
      "id": "uuid",
      "name": "Margherita Pizza",
      "slug": "margherita-pizza",
      "description": "Classic margherita",
      "price": 299.00,
      "discounted_price": 249.00,
      "vendor": "vendor-uuid",
      "category": "Pizza",
      "is_available": true,
      "image": "https://example.com/pizza.jpg"
    }
  ]
}
```

### Get Product Details

**Endpoint:** `GET /api/products/{slug}/`

**Description:** Get detailed product information.

**Authentication:** Not required (public)

**Response (200 OK):**
```json
{
  "id": "uuid",
  "name": "Margherita Pizza",
  "slug": "margherita-pizza",
  "description": "Classic margherita pizza",
  "price": 299.00,
  "discounted_price": 249.00,
  "vendor": {
    "id": "uuid",
    "name": "Pizza Palace"
  },
  "category": "Pizza",
  "is_available": true,
  "images": ["https://example.com/pizza1.jpg"],
  "variants": [
    {
      "id": "uuid",
      "name": "Size",
      "options": [
        {"name": "Small", "price": 0},
        {"name": "Large", "price": 100}
      ]
    }
  ]
}
```

---

## Cart Endpoints

### Get Cart

**Endpoint:** `GET /api/cart/?vendor={vendor_id}`

**Description:** Get user's shopping cart for a specific vendor.

**Authentication:** Required

**Query Parameters:**
- `vendor` - Vendor ID (required)

**Response (200 OK):**
```json
{
  "id": "uuid",
  "vendor": {
    "id": "uuid",
    "name": "Pizza Palace"
  },
  "items": [
    {
      "id": 1,
      "product": {
        "id": "uuid",
        "name": "Margherita Pizza",
        "price": 299.00
      },
      "quantity": 2,
      "unit_price": 299.00,
      "total_price": 598.00
    }
  ],
  "subtotal": 598.00,
  "total": 623.00
}
```

### Add Item to Cart

**Endpoint:** `POST /api/cart/items/`

**Description:** Add a product to the cart.

**Authentication:** Required

**Request Body:**
```json
{
  "product": "product-uuid",
  "quantity": 2,
  "variant": "variant-uuid"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "product": {
    "id": "uuid",
    "name": "Margherita Pizza"
  },
  "quantity": 2,
  "total_price": 598.00
}
```

### Update Cart Item

**Endpoint:** `PATCH /api/cart/items/{id}/`

**Description:** Update quantity of a cart item.

**Authentication:** Required

**Request Body:**
```json
{
  "quantity": 3
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "quantity": 3,
  "total_price": 897.00
}
```

### Remove Cart Item

**Endpoint:** `DELETE /api/cart/items/{id}/`

**Description:** Remove an item from cart.

**Authentication:** Required

**Response (204 No Content)**

---

## Order Endpoints

### List Orders

**Endpoint:** `GET /api/orders/`

**Description:** Get list of user's orders.

**Authentication:** Required

**Query Parameters:**
- `status` - Filter by order status
- `page` - Page number

**Response (200 OK):**
```json
{
  "count": 20,
  "results": [
    {
      "id": "uuid",
      "order_number": "ORD-2024-001",
      "vendor": {
        "name": "Pizza Palace"
      },
      "total_amount": 623.00,
      "order_status": "confirmed",
      "payment_status": "completed",
      "order_placed_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Create Order

**Endpoint:** `POST /api/orders/`

**Description:** Create a new order.

**Authentication:** Required

**Request Body:**
```json
{
  "vendor": "vendor-uuid",
  "delivery_address": 1,
  "items": [
    {
      "product": "product-uuid",
      "quantity": 2,
      "price": 299.00
    }
  ],
  "subtotal": 598.00,
  "delivery_fee": 25.00,
  "total_amount": 623.00,
  "payment_method": "cod",
  "scheduled_delivery_time": "2024-01-15T12:00:00Z"
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "order_number": "ORD-2024-001",
  "status": "pending",
  "total_amount": 623.00,
  "payment_status": "pending"
}
```

### Get Order Details

**Endpoint:** `GET /api/orders/{id}/`

**Description:** Get detailed order information.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "id": "uuid",
  "order_number": "ORD-2024-001",
  "vendor": {
    "id": "uuid",
    "name": "Pizza Palace"
  },
  "items": [
    {
      "product": {
        "name": "Margherita Pizza"
      },
      "quantity": 2,
      "price": 299.00
    }
  ],
  "total_amount": 623.00,
  "order_status": "confirmed",
  "payment_status": "completed",
  "delivery_status": "out_for_delivery",
  "order_placed_at": "2024-01-15T10:30:00Z"
}
```

---

## Payment Endpoints

### Create Paytm Order

**Endpoint:** `POST /api/payments/paytm/create-order/`

**Description:** Create a Paytm payment order.

**Authentication:** Required

**Request Body:**
```json
{
  "order_id": "order-uuid"
}
```

**Response (200 OK):**
```json
{
  "status": "created",
  "order_id": "order-uuid",
  "paytm_order_id": "ORDER_ORD-2024-001_1234567890",
  "paytm_merchant_id": "MERCHANT_ID",
  "paytm_params": {
    "MID": "MERCHANT_ID",
    "ORDER_ID": "ORDER_ORD-2024-001_1234567890",
    "TXN_AMOUNT": "623.00",
    "CUST_ID": "user-uuid",
    "CHECKSUMHASH": "checksum_hash"
  },
  "paytm_url": "https://securegw-stage.paytm.in/theia/processTransaction",
  "amount": 623.00
}
```

### Verify Payment

**Endpoint:** `POST /api/payments/paytm/verify/`

**Description:** Verify Paytm payment after completion.

**Authentication:** Required (or AllowAny for callback)

**Request Body (Form Data):**
```
ORDERID=ORDER_ORD-2024-001_1234567890
TXNID=TXN123456
STATUS=TXN_SUCCESS
CHECKSUMHASH=checksum_hash
```

**Response (200 OK):**
```json
{
  "status": "success",
  "order_id": "order-uuid",
  "order_number": "ORD-2024-001",
  "payment_id": "TXN123456"
}
```

---

## Wallet Endpoints

### Get Wallet

**Endpoint:** `GET /api/wallet/`

**Description:** Get user's wallet balance.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "id": "uuid",
  "balance": 500.00,
  "currency": "INR"
}
```

### Get Wallet Transactions

**Endpoint:** `GET /api/wallet/transactions/`

**Description:** Get wallet transaction history.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "count": 10,
  "results": [
    {
      "id": "uuid",
      "amount": 100.00,
      "transaction_type": "credit",
      "description": "Order refund",
      "created_on": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

## Notification Endpoints

### List Notifications

**Endpoint:** `GET /api/notifications/`

**Description:** Get user's notifications.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "count": 15,
  "results": [
    {
      "id": "uuid",
      "title": "Order Confirmed",
      "message": "Your order ORD-2024-001 has been confirmed",
      "type": "order",
      "is_read": false,
      "created_on": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Mark All as Read

**Endpoint:** `POST /api/notifications/mark-all-read/`

**Description:** Mark all notifications as read.

**Authentication:** Required

**Response (200 OK):**
```json
{
  "message": "All notifications marked as read"
}
```

---

## Delivery Endpoints

### Get Delivery Dashboard

**Endpoint:** `GET /api/delivery/dashboard/`

**Description:** Get delivery person dashboard data.

**Authentication:** Required (Delivery Person role)

**Response (200 OK):**
```json
{
  "delivery_person": {
    "id": "uuid",
    "user_name": "John Doe",
    "rating": 4.8,
    "total_deliveries": 150
  },
  "is_online": true,
  "active_assignments": [...],
  "today_stats": {
    "earnings": 500.00,
    "deliveries": 5,
    "distance_km": 25.5
  }
}
```

### Toggle Online Status

**Endpoint:** `POST /api/delivery/toggle-online/`

**Description:** Toggle delivery person online/offline status.

**Authentication:** Required (Delivery Person role)

**Request Body:**
```json
{
  "is_online": true
}
```

**Response (200 OK):**
```json
{
  "is_online": true,
  "message": "Status updated successfully"
}
```

---

## Dashboard Endpoints (Hotel Owner)

### Get Dashboard Home

**Endpoint:** `GET /api/dashboard/home/`

**Description:** Get hotel owner dashboard statistics.

**Authentication:** Required (Hotel Owner role)

**Response (200 OK):**
```json
{
  "live_orders": 5,
  "today_revenue": 5000.00,
  "current_rating": 4.5,
  "today_orders": 20,
  "delayed_orders": 1,
  "complaints": 0,
  "avg_delivery_time": 30,
  "customer_satisfaction": 95,
  "restaurant_status": "online"
}
```

### Get Dashboard Orders

**Endpoint:** `GET /api/dashboard/orders/`

**Description:** Get orders for hotel owner dashboard.

**Authentication:** Required (Hotel Owner role)

**Query Parameters:**
- `status` - Filter by status
- `page` - Page number

**Response (200 OK):**
```json
{
  "count": 50,
  "results": [
    {
      "id": "uuid",
      "order_number": "ORD-2024-001",
      "customer_name": "John Doe",
      "total_amount": 623.00,
      "order_status": "confirmed",
      "order_placed_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

## Utility Endpoints

### Search

**Endpoint:** `GET /api/search/`

**Description:** Search across vendors and products.

**Query Parameters:**
- `q` - Search query
- `type` - Search type (vendor, product, all)

**Response (200 OK):**
```json
{
  "vendors": [...],
  "products": [...]
}
```

### Geocode Address

**Endpoint:** `POST /api/location/geocode/`

**Description:** Convert address to coordinates.

**Authentication:** Required

**Request Body:**
```json
{
  "address": "123 Main St, Mumbai, India"
}
```

**Response (200 OK):**
```json
{
  "latitude": 19.0760,
  "longitude": 72.8777,
  "formatted_address": "123 Main St, Mumbai, Maharashtra, India"
}
```

---

For more detailed information about specific endpoints, refer to the Swagger documentation or contact the development team.

