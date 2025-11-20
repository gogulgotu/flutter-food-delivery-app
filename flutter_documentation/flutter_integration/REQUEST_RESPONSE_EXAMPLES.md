# Request/Response Examples

This document provides detailed request/response examples for common API operations in Flutter.

## Table of Contents

1. [Authentication Examples](#authentication-examples)
2. [User Management Examples](#user-management-examples)
3. [Order Management Examples](#order-management-examples)
4. [Payment Examples](#payment-examples)
5. [Cart Examples](#cart-examples)

---

## Authentication Examples

### 1. Register User

**Request:**
```dart
final authService = AuthService();

final result = await authService.register(
  email: 'user@example.com',
  password: 'SecurePassword123!',
  firstName: 'John',
  lastName: 'Doe',
  phoneNumber: '+919876543210',
);
```

**Response:**
```json
{
  "message": "User registered successfully. Please verify your phone number with OTP to complete registration.",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "requires_otp_verification": true
}
```

### 2. Login with Email/Password

**Request:**
```dart
final result = await authService.login(
  email: 'user@example.com',
  password: 'password123',
);
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "user_role_name": "Customer"
  }
}
```

### 3. OTP Login Flow

**Step 1: Send OTP**
```dart
final result = await authService.sendOTP('+919876543210');
```

**Response:**
```json
{
  "message": "OTP sent successfully",
  "otp": "123456",
  "expires_in": 300
}
```

**Step 2: Verify OTP**
```dart
final result = await authService.verifyOTP(
  mobileNumber: '+919876543210',
  otp: '123456',
);
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "phone_number": "+919876543210",
    "user_role_name": "Customer"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  },
  "user_type": "existing"
}
```

---

## User Management Examples

### Get User Profile

**Request:**
```dart
final userService = UserService();
final user = await userService.getProfile();
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+919876543210",
  "user_role_name": "Customer",
  "is_verified": true,
  "created_at": "2024-01-01T00:00:00Z"
}
```

### Update User Profile

**Request:**
```dart
final user = await userService.updateProfile(
  firstName: 'John',
  lastName: 'Smith',
  email: 'newemail@example.com',
);
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "newemail@example.com",
  "first_name": "John",
  "last_name": "Smith",
  "phone_number": "+919876543210"
}
```

---

## Order Management Examples

### Create Order

**Request:**
```dart
final orderService = OrderService();

final order = await orderService.createOrder(
  vendorId: 'vendor-uuid',
  deliveryAddressId: 1,
  items: [
    {
      'product': 'product-uuid-1',
      'quantity': 2,
      'price': 299.00,
    },
    {
      'product': 'product-uuid-2',
      'quantity': 1,
      'price': 150.00,
    },
  ],
  subtotal: 748.00,
  deliveryFee: 25.00,
  totalAmount: 773.00,
  paymentMethod: 'cod',
  customerLatitude: 19.0760,
  customerLongitude: 72.8777,
);
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD-2024-001",
  "vendor": {
    "id": "vendor-uuid",
    "name": "Pizza Palace"
  },
  "total_amount": "773.00",
  "order_status": "pending",
  "payment_status": "pending",
  "order_placed_at": "2024-01-15T10:30:00Z"
}
```

### Get Orders List

**Request:**
```dart
final orders = await orderService.getOrders(
  status: 'confirmed',
  page: 1,
);
```

**Response:**
```json
{
  "count": 50,
  "next": "http://api.example.com/api/orders/?page=2",
  "previous": null,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "order_number": "ORD-2024-001",
      "vendor": {
        "name": "Pizza Palace"
      },
      "total_amount": "773.00",
      "order_status": "confirmed",
      "payment_status": "completed",
      "order_placed_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Get Order Details

**Request:**
```dart
final order = await orderService.getOrderDetails('order-uuid');
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD-2024-001",
  "vendor": {
    "id": "vendor-uuid",
    "name": "Pizza Palace",
    "address": "123 Food Street"
  },
  "items": [
    {
      "id": "item-uuid",
      "product": {
        "id": "product-uuid",
        "name": "Margherita Pizza",
        "price": "299.00"
      },
      "quantity": 2,
      "unit_price": "299.00",
      "total_price": "598.00"
    }
  ],
  "delivery_address": {
    "title": "Home",
    "address_line_1": "123 Main St",
    "city": "Mumbai",
    "postal_code": "400001"
  },
  "subtotal": "748.00",
  "delivery_fee": "25.00",
  "total_amount": "773.00",
  "order_status": "confirmed",
  "payment_status": "completed",
  "delivery_status": "out_for_delivery",
  "order_placed_at": "2024-01-15T10:30:00Z",
  "estimated_delivery_time": "2024-01-15T11:00:00Z"
}
```

---

## Payment Examples

### Create Paytm Payment Order

**Request:**
```dart
final paymentService = PaymentService();
final paymentData = await paymentService.createPaytmOrder('order-uuid');
```

**Response:**
```json
{
  "status": "created",
  "order_id": "order-uuid",
  "order_number": "ORD-2024-001",
  "paytm_order_id": "ORDER_ORD-2024-001_1705312200",
  "paytm_merchant_id": "MERCHANT_ID",
  "paytm_params": {
    "MID": "MERCHANT_ID",
    "WEBSITE": "WEBSTAGING",
    "CHANNEL_ID": "WEB",
    "INDUSTRY_TYPE_ID": "Retail",
    "ORDER_ID": "ORDER_ORD-2024-001_1705312200",
    "TXN_AMOUNT": "773.00",
    "CUST_ID": "user-uuid",
    "CALLBACK_URL": "https://yourapp.com/payment/paytm/callback",
    "EMAIL": "user@example.com",
    "MOBILE_NO": "+919876543210",
    "CHECKSUMHASH": "checksum_hash_string"
  },
  "paytm_url": "https://securegw-stage.paytm.in/theia/processTransaction",
  "amount": 773.00,
  "amount_readable": 773.00,
  "currency": "INR"
}
```

**Flutter Implementation:**
```dart
// Create form and submit to Paytm
void initiatePaytmPayment(Map<String, dynamic> paymentData) {
  final form = html.FormElement();
  form.method = 'POST';
  form.action = paymentData['paytm_url'];
  
  paymentData['paytm_params'].forEach((key, value) {
    final input = html.InputElement();
    input.type = 'hidden';
    input.name = key;
    input.value = value.toString();
    form.children.add(input);
  });
  
  html.document.body!.children.add(form);
  form.submit();
}
```

### Verify Payment (Callback)

**Request (from Paytm callback):**
```dart
// Paytm redirects to callback URL with form data
final paymentParams = {
  'ORDERID': 'ORDER_ORD-2024-001_1705312200',
  'TXNID': 'TXN123456789',
  'STATUS': 'TXN_SUCCESS',
  'RESPMSG': 'Txn Success',
  'CHECKSUMHASH': 'checksum_hash',
};

final result = await paymentService.verifyPaytmPayment(paymentParams);
```

**Response:**
```json
{
  "status": "success",
  "order_id": "order-uuid",
  "order_number": "ORD-2024-001",
  "payment_id": "TXN123456789"
}
```

---

## Cart Examples

### Get Cart

**Request:**
```dart
final cartService = CartService();
final cart = await cartService.getCart('vendor-uuid');
```

**Response:**
```json
{
  "id": "cart-uuid",
  "vendor": {
    "id": "vendor-uuid",
    "name": "Pizza Palace"
  },
  "items": [
    {
      "id": 1,
      "product": {
        "id": "product-uuid",
        "name": "Margherita Pizza",
        "price": "299.00",
        "image": "https://example.com/pizza.jpg"
      },
      "quantity": 2,
      "unit_price": "299.00",
      "total_price": "598.00"
    }
  ],
  "subtotal": "598.00",
  "delivery_fee": "25.00",
  "tax": "29.90",
  "total": "652.90"
}
```

### Add Item to Cart

**Request:**
```dart
final item = await cartService.addToCart(
  productId: 'product-uuid',
  quantity: 2,
  variantId: 'variant-uuid', // Optional
);
```

**Response:**
```json
{
  "id": 1,
  "product": {
    "id": "product-uuid",
    "name": "Margherita Pizza",
    "price": "299.00"
  },
  "quantity": 2,
  "unit_price": "299.00",
  "total_price": "598.00"
}
```

### Update Cart Item

**Request:**
```dart
final item = await cartService.updateCartItem(
  itemId: 1,
  quantity: 3,
);
```

**Response:**
```json
{
  "id": 1,
  "quantity": 3,
  "unit_price": "299.00",
  "total_price": "897.00"
}
```

### Remove from Cart

**Request:**
```dart
await cartService.removeFromCart(1);
```

**Response:**
```
204 No Content
```

---

## Error Response Examples

### Validation Error (400)

**Request:**
```dart
try {
  await authService.register(
    email: 'invalid-email',
    password: '123',
  );
} catch (e) {
  // Handle error
}
```

**Response:**
```json
{
  "error": "Validation failed",
  "detail": {
    "email": ["Enter a valid email address."],
    "password": [
      "This password is too short. It must contain at least 8 characters.",
      "This password is too common."
    ]
  }
}
```

### Authentication Error (401)

**Response:**
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

### Not Found Error (404)

**Response:**
```json
{
  "detail": "Not found."
}
```

---

## Complete Flutter Widget Example

```dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await _orderService.getOrders();
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Orders')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(child: Text('No orders found'))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return ListTile(
                          title: Text('Order ${order.orderNumber}'),
                          subtitle: Text('₹${order.totalAmount}'),
                          trailing: Text(order.orderStatus),
                          onTap: () {
                            // Navigate to order details
                          },
                        );
                      },
                    ),
    );
  }
}
```

---

For more examples, refer to the [API_SERVICE_EXAMPLE.dart](./API_SERVICE_EXAMPLE.dart) file.

