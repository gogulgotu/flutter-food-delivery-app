# Order Placement API Documentation

## Overview

This document provides comprehensive documentation for the order placement API endpoints used in the checkout flow. It covers order creation, payment processing, validation, and all related functionality.

**Base URL:** `/api/orders/`

**Authentication:** All endpoints require authentication (JWT token)

---

## Table of Contents

1. [Order Creation Endpoint](#order-creation-endpoint)
2. [Payment Processing Endpoints](#payment-processing-endpoints)
3. [Request/Response Formats](#requestresponse-formats)
4. [Validation Rules](#validation-rules)
5. [Special Features](#special-features)
6. [Error Handling](#error-handling)
7. [Complete Checkout Flow](#complete-checkout-flow)
8. [Code Examples](#code-examples)

---

## Order Creation Endpoint

### Create Order

**Endpoint:** `POST /api/orders/`

**Method:** `POST`

**Authentication:** Required

**Description:** Creates a new order with items, delivery address, payment method, and all order details. This is the primary endpoint called during checkout.

**⚠️ Important:** The endpoint URL **must end with a trailing slash**: `/api/orders/` (not `/api/orders`)

---

### Request Body Structure

#### Required Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `vendor` | UUID/String | Yes | Vendor ID (restaurant/hotel) |
| `delivery_address` | Integer | Yes | Address ID from user's saved addresses |
| `items` | Array | Yes | Array of order items (at least one required) |
| `subtotal` | Decimal/String | Yes | Subtotal amount (recalculated by backend) |
| `delivery_fee` | Decimal/String | Yes | Delivery fee (can use vendor default) |
| `total_amount` | Decimal/String | Yes | Total amount (recalculated by backend) |

#### Optional Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `payment_method` | String | No | Payment method: `"cod"` or `"paytm"` (default: `"pending"`) |
| `payment_status` | String | No | Payment status (default: `"pending"`) |
| `scheduled_delivery_time` | ISO DateTime | No | Scheduled delivery time (required for meat orders) |
| `customer_latitude` | Decimal/String | No | Customer GPS latitude |
| `customer_longitude` | Decimal/String | No | Customer GPS longitude |
| `delivery_instructions` | String | No | Special delivery instructions |
| `customer_notes` | String | No | Customer notes for vendor |
| `service_fee` | Decimal/String | No | Service fee (default: 0.00) |
| `tax_amount` | Decimal/String | No | Tax amount (calculated: 5% of subtotal) |
| `discount_amount` | Decimal/String | No | Discount amount (default: 0.00) |

#### Items Array Structure

Each item in the `items` array must have:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `product` or `product_id` | UUID/String | Yes | Product ID |
| `quantity` | Integer | Yes | Quantity (must be >= 1) |
| `price` | Decimal/String | No | Unit price (uses product price if not provided) |
| `variant` | UUID/String | No | Product variant ID (if applicable) |
| `special_instructions` | String | No | Special instructions for this item |

---

### Example Request

```json
{
  "vendor": "550e8400-e29b-41d4-a716-446655440000",
  "delivery_address": 1,
  "items": [
    {
      "product": "660e8400-e29b-41d4-a716-446655440000",
      "quantity": 2,
      "price": "299.00",
      "variant": null,
      "special_instructions": "Extra spicy"
    },
    {
      "product": "770e8400-e29b-41d4-a716-446655440000",
      "quantity": 1,
      "price": "150.00"
    }
  ],
  "subtotal": "748.00",
  "delivery_fee": "25.00",
  "service_fee": "0.00",
  "tax_amount": "37.40",
  "discount_amount": "0.00",
  "total_amount": "810.40",
  "payment_method": "cod",
  "payment_status": "pending",
  "customer_latitude": "19.076000",
  "customer_longitude": "72.877700",
  "delivery_instructions": "Ring doorbell twice",
  "customer_notes": "Please pack well"
}
```

---

### Response (201 Created)

```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "user": "990e8400-e29b-41d4-a716-446655440000",
  "user_name": "John Doe",
  "user_phone": "+919876543210",
  "vendor": "550e8400-e29b-41d4-a716-446655440000",
  "vendor_name": "Pizza Palace",
  "vendor_slug": "pizza-palace",
  "vendor_phone": "+919123456789",
  "delivery_person": null,
  "delivery_person_name": null,
  "order_status": "ORDER_PLACED",
  "order_status_name": "Order Placed",
  "order_status_code": "ORDER_PLACED",
  "delivery_status": "assigned",
  "delivery_status_name": "Assigned",
  "delivery_address": 1,
  "delivery_address_details": {
    "id": 1,
    "title": "Home",
    "address_line_1": "123 Main Street",
    "address_line_2": "Apt 4B",
    "city": "Mumbai",
    "state": "Maharashtra",
    "country": "India",
    "postal_code": "400001",
    "latitude": "19.076000",
    "longitude": "72.877700",
    "is_default": true
  },
  "delivery_address_full": "123 Main Street, Apt 4B, Mumbai, Maharashtra 400001",
  "delivery_instructions": "Ring doorbell twice",
  "subtotal": "748.00",
  "delivery_fee": "25.00",
  "service_fee": "0.00",
  "tax_amount": "37.40",
  "discount_amount": "0.00",
  "total_amount": "810.40",
  "order_placed_at": "2024-01-15T10:30:00Z",
  "estimated_delivery_time": "2024-01-15T12:15:00Z",
  "scheduled_delivery_time": null,
  "payment_method": "cod",
  "payment_status": "pending",
  "payment_reference": null,
  "tracking_number": null,
  "current_latitude": null,
  "current_longitude": null,
  "customer_latitude": "19.076000",
  "customer_longitude": "72.877700",
  "restaurant_latitude": "19.082000",
  "restaurant_longitude": "72.880000",
  "customer_notes": "Please pack well",
  "vendor_notes": null,
  "delivery_notes": null,
  "items": [
    {
      "id": "aa0e8400-e29b-41d4-a716-446655440000",
      "product": {
        "id": "660e8400-e29b-41d4-a716-446655440000",
        "name": "Margherita Pizza",
        "slug": "margherita-pizza",
        "price": "299.00",
        "discounted_price": "299.00"
      },
      "variant": null,
      "quantity": 2,
      "unit_price": "299.00",
      "total_price": "598.00",
      "special_instructions": "Extra spicy"
    },
    {
      "id": "bb0e8400-e29b-41d4-a716-446655440000",
      "product": {
        "id": "770e8400-e29b-41d4-a716-446655440000",
        "name": "Garlic Bread",
        "slug": "garlic-bread",
        "price": "150.00",
        "discounted_price": "150.00"
      },
      "variant": null,
      "quantity": 1,
      "unit_price": "150.00",
      "total_price": "150.00",
      "special_instructions": ""
    }
  ],
  "otp_info": null
}
```

---

## Backend Processing

### 1. Validation Phase

#### Item Validation
- ✅ At least one item required
- ✅ Each item must have `product` or `product_id`
- ✅ Each item must have `quantity >= 1`
- ✅ Product must exist and be available
- ✅ Variant must exist if provided

#### Vendor Validation
- ✅ Vendor must exist
- ✅ Vendor must be active

#### Address Validation
- ✅ Delivery address must be provided
- ✅ Address must belong to authenticated user
- ✅ Address must exist

#### Meat Order Validation
- ✅ If order contains meat products, `scheduled_delivery_time` is **required**
- ✅ Meat orders must be scheduled for **Saturday or Sunday**
- ✅ Meat orders must be scheduled between **6 AM - 8 AM**
- ✅ Scheduled time must be in valid ISO format

#### Coordinate Validation
- ✅ If `customer_latitude` provided, `customer_longitude` must also be provided
- ✅ Coordinates must be valid (latitude: -90 to 90, longitude: -180 to 180)
- ✅ If coordinates not provided, attempts to geocode address
- ✅ If geocoding fails, returns error with `requires_location: true`

### 2. Price Calculation Phase

**Backend Recalculates All Prices:**

```python
# Subtotal calculation
subtotal = sum(item['price'] * item['quantity'] for item in items)

# Tax calculation (5% of subtotal)
tax_amount = subtotal * 0.05

# Total calculation
total_amount = subtotal + delivery_fee + service_fee + tax_amount - discount_amount
```

**Important:** Backend **overrides** frontend-provided prices to prevent manipulation and floating-point errors.

### 3. Order Creation Phase

1. **Create Order Record:**
   - Set `order_status` to `ORDER_PLACED`
   - Set `delivery_status` to `assigned`
   - Generate unique `order_number` (format: `ORD` + 8 digits)
   - Set `order_placed_at` to current timestamp

2. **Create Order Items:**
   - Create `OrderItem` record for each item
   - Link to product and variant (if applicable)
   - Store unit price and total price
   - Store special instructions

3. **Create Order Tracking:**
   - Create initial tracking record with status `ORDER_PLACED`
   - Description: "Order placed by customer"

4. **Publish Order Event:**
   - Publish `order.created` event to event bus
   - Includes payment data for processing

5. **Geocode Addresses (if needed):**
   - If restaurant coordinates missing, geocode restaurant address
   - If customer coordinates missing, geocode customer address
   - Update address records with coordinates

---

## Payment Processing Endpoints

### 1. Create Paytm Payment Order

**Endpoint:** `POST /api/payments/paytm/create-order/`

**Method:** `POST`

**Authentication:** Required

**Description:** Creates a Paytm payment order for online payment processing. Called after order creation when user selects "Pay Online (Paytm)".

**Request Body:**

```json
{
  "order_id": "880e8400-e29b-41d4-a716-446655440000"
}
```

**Response (200 OK):**

```json
{
  "status": "created",
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "paytm_order_id": "ORDER_ORD12345678_1705312200",
  "paytm_merchant_id": "MERCHANT_ID",
  "paytm_params": {
    "MID": "MERCHANT_ID",
    "ORDER_ID": "ORDER_ORD12345678_1705312200",
    "TXN_AMOUNT": "810.40",
    "CUST_ID": "990e8400-e29b-41d4-a716-446655440000",
    "INDUSTRY_TYPE_ID": "Retail",
    "CHANNEL_ID": "WAP",
    "WEBSITE": "WEBSTAGING",
    "CALLBACK_URL": "http://localhost:3000/payment/paytm/callback",
    "CHECKSUMHASH": "checksum_hash_here"
  },
  "paytm_url": "https://securegw-stage.paytm.in/theia/processTransaction",
  "amount": 810.40,
  "amount_readable": 810.40,
  "currency": "INR"
}
```

**Validation:**
- ✅ Order must exist
- ✅ Order must belong to authenticated user
- ✅ Order payment status must be `pending`
- ✅ Order total must be > 0
- ✅ Paytm must be configured

**Error Responses:**

**400 Bad Request - Order Already Paid:**
```json
{
  "error": "Order is already paid."
}
```

**400 Bad Request - Invalid Order Total:**
```json
{
  "error": "Order total must be greater than zero to initiate online payment."
}
```

**503 Service Unavailable - Paytm Not Configured:**
```json
{
  "error": "Paytm payment gateway is not configured"
}
```

---

### 2. Verify Paytm Payment

**Endpoint:** `POST /api/payments/paytm/verify/`

**Method:** `POST`

**Authentication:** Required (or AllowAny for callback)

**Description:** Verifies Paytm payment after user completes payment on Paytm gateway. Called from Paytm callback URL.

**Request Body (Form Data from Paytm):**

```
ORDERID=ORDER_ORD12345678_1705312200
TXNID=TXN123456789
STATUS=TXN_SUCCESS
CHECKSUMHASH=checksum_hash_here
RESPCODE=01
RESPMSG=Txn Success
BANKTXNID=BANK123456
TXNAMOUNT=810.40
CURRENCY=INR
GATEWAYNAME=WALLET
PAYMENTMODE=PPI
```

**Response (200 OK):**

```json
{
  "status": "success",
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "payment_id": "TXN123456789",
  "message": "Payment verified successfully"
}
```

**Error Responses:**

**400 Bad Request - Payment Failed:**
```json
{
  "status": "failed",
  "error": "Payment verification failed",
  "message": "Transaction failed on Paytm"
}
```

**400 Bad Request - Invalid Checksum:**
```json
{
  "error": "Invalid checksum"
}
```

---

## Validation Rules

### Order Items

| Rule | Description |
|------|-------------|
| Minimum Items | At least one item required |
| Product ID | Each item must have `product` or `product_id` |
| Quantity | Must be >= 1 |
| Product Exists | Product must exist in database |
| Variant Exists | If variant provided, must exist |

### Delivery Address

| Rule | Description |
|------|-------------|
| Required | Delivery address ID is required |
| User Ownership | Address must belong to authenticated user |
| Exists | Address must exist in database |

### GPS Coordinates

| Rule | Description |
|------|-------------|
| Both Required | If latitude provided, longitude must also be provided |
| Valid Range | Latitude: -90 to 90, Longitude: -180 to 180 |
| Geocoding Fallback | If not provided, attempts to geocode address |

### Meat Orders

| Rule | Description |
|------|-------------|
| Scheduled Time Required | `scheduled_delivery_time` is mandatory |
| Day Restriction | Must be Saturday (5) or Sunday (6) |
| Time Restriction | Must be between 6 AM - 8 AM |
| Format | Must be valid ISO 8601 datetime |

### Scheduled Delivery (Non-Meat)

| Rule | Description |
|------|-------------|
| Future Time | Must be in the future |
| Format | Must be valid ISO 8601 datetime |

### Pricing

| Rule | Description |
|------|-------------|
| Recalculated | All prices recalculated by backend |
| Decimal Precision | All amounts rounded to 2 decimal places |
| Tax Rate | Tax is 5% of subtotal |
| Total Validation | Total must match: subtotal + fees + tax - discount |

---

## Special Features

### 1. Automatic Price Recalculation

**Purpose:** Prevent price manipulation and floating-point errors.

**Process:**
1. Frontend sends calculated prices
2. Backend recalculates all prices from scratch
3. Backend overrides frontend prices with server-calculated values
4. Ensures accuracy and security

**Example:**
```python
# Frontend sends: subtotal: 87.99000000000001
# Backend recalculates: subtotal: 87.99
# Backend uses: subtotal: 87.99
```

---

### 2. Meat Order Scheduling

**Requirements:**
- Meat orders **must** be scheduled
- Only Saturday or Sunday allowed
- Only 6 AM - 8 AM time window
- Validation happens on backend

**Validation Logic:**
```python
if has_meat_products:
    if not scheduled_delivery_time:
        return error("Meat orders must be scheduled")
    
    scheduled_local = timezone.localtime(scheduled_time)
    weekday = scheduled_local.weekday()
    
    if weekday not in [5, 6]:  # Saturday=5, Sunday=6
        return error("Must be Saturday or Sunday")
    
    hour = scheduled_local.hour
    if hour < 6 or hour >= 8:
        return error("Must be between 6 AM - 8 AM")
```

---

### 3. GPS Coordinate Collection

**Priority Order:**
1. **Provided Coordinates** - Use `customer_latitude` and `customer_longitude` from request
2. **Address Coordinates** - Use coordinates from selected address
3. **Geocoding** - Geocode address to get coordinates
4. **Error** - If all fail, return error with `requires_location: true`

**Coordinate Update:**
- If geocoding succeeds, address is updated with coordinates
- Coordinates are stored in both order and address records

---

### 4. Order Tracking

**Automatic Tracking Creation:**
- Initial tracking record created with status `ORDER_PLACED`
- Description: "Order placed by customer"
- Timestamp: Order creation time

**Tracking Flow:**
- Order placed → `ORDER_PLACED`
- Restaurant confirms → `ORDER_CONFIRMED`
- Restaurant starts preparing → `PREPARING`
- Order ready → `READY_FOR_PICKUP`
- Delivery person picks up → `OUT_FOR_DELIVERY`
- Order delivered → `DELIVERED`

---

### 5. Event Publishing

**Order Created Event:**
- Published to event bus after order creation
- Includes order data and payment information
- Triggers notifications and other processes
- Non-blocking (order creation succeeds even if event fails)

---

## Error Handling

### Common Error Responses

#### 400 Bad Request

**Missing Items:**
```json
{
  "error": "Order must contain at least one item"
}
```

**Missing Product ID:**
```json
{
  "error": "Product ID is required for all order items"
}
```

**Invalid Vendor:**
```json
{
  "error": "Invalid vendor specified for order"
}
```

**Missing Delivery Address:**
```json
{
  "error": "Delivery address is required"
}
```

**Invalid Delivery Address:**
```json
{
  "error": "Invalid delivery address specified"
}
```

**Meat Order Without Scheduling:**
```json
{
  "error": "Meat orders must be scheduled for Saturday or Sunday between 6 AM to 8 AM"
}
```

**Invalid Scheduled Time:**
```json
{
  "error": "Meat orders can only be scheduled for Saturday or Sunday"
}
```

```json
{
  "error": "Meat orders can only be scheduled between 6 AM to 8 AM"
}
```

```json
{
  "error": "Scheduled delivery time must be in the future"
}
```

**Invalid Coordinates:**
```json
{
  "error": "Invalid GPS coordinates: Latitude must be between -90 and 90",
  "requires_location": true
}
```

**Location Required:**
```json
{
  "error": "Could not determine delivery location coordinates. Please enable GPS or provide coordinates.",
  "requires_location": true
}
```

**Invalid Scheduled Time Format:**
```json
{
  "error": "Invalid scheduled_delivery_time format: ..."
}
```

#### 401 Unauthorized

**Missing Token:**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

**Invalid Token:**
```json
{
  "detail": "Given token not valid for any token type"
}
```

#### 500 Internal Server Error

**Order Status Not Found:**
```json
{
  "error": "OrderStatus reference data not found"
}
```

**Delivery Status Not Found:**
```json
{
  "error": "DeliveryStatus reference data not found"
}
```

---

## Complete Checkout Flow

### Step-by-Step Process

```
1. User clicks "Place Order"
   ↓
2. Frontend validates:
   - Location collected
   - Address selected
   - Payment method selected
   - Cart has items
   ↓
3. Build order payload:
   - Items from cart
   - Selected address
   - GPS coordinates
   - Payment method
   - Calculated totals
   ↓
4. POST /api/orders/
   - Backend validates all data
   - Recalculates prices
   - Creates order
   - Creates order items
   - Creates tracking record
   - Publishes event
   ↓
5. Check payment method:
   
   If COD:
   - Clear cart
   - Redirect to order detail page
   
   If Paytm:
   - POST /api/payments/paytm/create-order/
   - Get Paytm payment parameters
   - Create form with Paytm params
   - Auto-submit to Paytm URL
   - User redirected to Paytm
   ↓
6. User completes payment on Paytm
   ↓
7. Paytm redirects to callback URL
   ↓
8. POST /api/payments/paytm/verify/
   - Verify payment checksum
   - Update order payment status
   - Update payment record
   ↓
9. Redirect to order detail page
```

---

## Code Examples

### JavaScript/React Example

```javascript
// Order Service
class OrderService {
  constructor(apiClient) {
    this.api = apiClient;
  }

  // Create order
  async createOrder(orderData) {
    try {
      const response = await this.api.post('/api/orders/', orderData);
      return response.data;
    } catch (error) {
      if (error.response?.data?.requires_location) {
        throw new Error('Location required. Please enable GPS.');
      }
      throw error;
    }
  }

  // Create Paytm payment order
  async createPaytmOrder(orderId) {
    const response = await this.api.post('/api/payments/paytm/create-order/', {
      order_id: orderId
    });
    return response.data;
  }

  // Verify Paytm payment
  async verifyPaytmPayment(paymentData) {
    const response = await this.api.post('/api/payments/paytm/verify/', paymentData);
    return response.data;
  }
}

// Usage in Checkout Component
const orderService = new OrderService(apiClient);

// Create order
const orderData = {
  vendor: selectedVendor.id,
  delivery_address: selectedAddress.id,
  items: cartItems.map(item => ({
    product: item.product.id,
    quantity: item.quantity,
    price: item.unit_price,
    variant: item.variant?.id || null,
    special_instructions: item.special_instructions || ''
  })),
  subtotal: cartSubtotal,
  delivery_fee: deliveryFee,
  service_fee: 0,
  tax_amount: taxAmount,
  discount_amount: discountAmount,
  total_amount: totalAmount,
  payment_method: selectedPaymentMethod,
  payment_status: 'pending',
  customer_latitude: location.latitude,
  customer_longitude: location.longitude,
  delivery_instructions: deliveryInstructions,
  scheduled_delivery_time: scheduledTime || null
};

try {
  const order = await orderService.createOrder(orderData);
  
  if (selectedPaymentMethod === 'paytm') {
    // Create Paytm order
    const paytmOrder = await orderService.createPaytmOrder(order.id);
    
    // Create and submit form to Paytm
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = paytmOrder.paytm_url;
    
    Object.entries(paytmOrder.paytm_params).forEach(([key, value]) => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = key;
      input.value = value;
      form.appendChild(input);
    });
    
    document.body.appendChild(form);
    form.submit();
  } else {
    // COD - redirect to order detail
    window.location.href = `/orders/${order.id}`;
  }
} catch (error) {
  if (error.message.includes('Location required')) {
    // Show location collection modal
    showLocationModal();
  } else {
    // Show error message
    showError(error.message);
  }
}
```

---

### Python/Django Example

```python
import requests

class OrderAPI:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def create_order(self, order_data):
        url = f'{self.base_url}/api/orders/'
        response = requests.post(url, headers=self.headers, json=order_data)
        response.raise_for_status()
        return response.json()
    
    def create_paytm_order(self, order_id):
        url = f'{self.base_url}/api/payments/paytm/create-order/'
        response = requests.post(
            url,
            headers=self.headers,
            json={'order_id': str(order_id)}
        )
        response.raise_for_status()
        return response.json()
    
    def verify_paytm_payment(self, payment_data):
        url = f'{self.base_url}/api/payments/paytm/verify/'
        response = requests.post(url, headers=self.headers, data=payment_data)
        response.raise_for_status()
        return response.json()

# Usage
api = OrderAPI('http://localhost:8000', 'your_jwt_token')

order_data = {
    'vendor': '550e8400-e29b-41d4-a716-446655440000',
    'delivery_address': 1,
    'items': [
        {
            'product': '660e8400-e29b-41d4-a716-446655440000',
            'quantity': 2,
            'price': '299.00'
        }
    ],
    'subtotal': '598.00',
    'delivery_fee': '25.00',
    'total_amount': '653.90',
    'payment_method': 'cod',
    'customer_latitude': '19.076000',
    'customer_longitude': '72.877700'
}

order = api.create_order(order_data)
print(f"Order created: {order['order_number']}")
```

---

### Flutter/Dart Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderService {
  final String baseUrl;
  final String token;

  OrderService(this.baseUrl, this.token);

  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // Create order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/'),
      headers: headers,
      body: json.encode(orderData),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      if (error['requires_location'] == true) {
        throw Exception('Location required. Please enable GPS.');
      }
      throw Exception(error['error'] ?? 'Failed to create order');
    } else {
      throw Exception('Failed to create order: ${response.statusCode}');
    }
  }

  // Create Paytm payment order
  Future<Map<String, dynamic>> createPaytmOrder(String orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/payments/paytm/create-order/'),
      headers: headers,
      body: json.encode({'order_id': orderId}),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create Paytm order');
    }
  }

  // Verify Paytm payment
  Future<Map<String, dynamic>> verifyPaytmPayment(Map<String, String> paymentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/payments/paytm/verify/'),
      headers: headers,
      body: paymentData,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Payment verification failed');
    }
  }
}

// Usage
final orderService = OrderService('http://localhost:8000', 'your_token');

final orderData = {
  'vendor': '550e8400-e29b-41d4-a716-446655440000',
  'delivery_address': 1,
  'items': [
    {
      'product': '660e8400-e29b-41d4-a716-446655440000',
      'quantity': 2,
      'price': '299.00',
    }
  ],
  'subtotal': '598.00',
  'delivery_fee': '25.00',
  'total_amount': '653.90',
  'payment_method': 'cod',
  'customer_latitude': '19.076000',
  'customer_longitude': '72.877700',
};

try {
  final order = await orderService.createOrder(orderData);
  print('Order created: ${order['order_number']}');
  
  if (order['payment_method'] == 'paytm') {
    final paytmOrder = await orderService.createPaytmOrder(order['id']);
    // Navigate to Paytm payment page
    // ...
  }
} catch (e) {
  if (e.toString().contains('Location required')) {
    // Show location collection UI
  } else {
    // Show error message
  }
}
```

---

## Best Practices

### 1. Always Use Trailing Slash

**Correct:**
```
POST /api/orders/
```

**Incorrect:**
```
POST /api/orders  ❌ (Will cause 500 error)
```

### 2. Handle Location Errors

- Check for `requires_location: true` in error response
- Prompt user to enable GPS or select location on map
- Retry order creation after location is collected

### 3. Validate Before Sending

- Validate all required fields on frontend
- Check coordinate ranges before sending
- Validate scheduled time format for meat orders
- Ensure at least one item in cart

### 4. Handle Price Recalculation

- Don't rely on frontend-calculated prices
- Backend will recalculate and override
- Use backend response for final amounts

### 5. Payment Flow

- For COD: Clear cart and redirect immediately
- For Paytm: Create payment order, then redirect
- Handle payment verification in callback
- Show loading states during payment processing

### 6. Error Handling

- Show user-friendly error messages
- Handle network errors with retry
- Handle validation errors with field-level feedback
- Log errors for debugging

---

## Summary

The Order Placement API provides:

- ✅ Complete order creation with validation
- ✅ Automatic price recalculation
- ✅ GPS coordinate handling
- ✅ Meat order scheduling validation
- ✅ Paytm payment integration
- ✅ Order tracking creation
- ✅ Event publishing
- ✅ Comprehensive error handling

**Key Endpoints:**
1. `POST /api/orders/` - Create order
2. `POST /api/payments/paytm/create-order/` - Create Paytm payment
3. `POST /api/payments/paytm/verify/` - Verify Paytm payment

**Important Notes:**
- Always use trailing slash in URLs
- Backend recalculates all prices
- Location is required (GPS or geocoding)
- Meat orders require Saturday/Sunday 6-8 AM scheduling
- Payment method determines next steps

