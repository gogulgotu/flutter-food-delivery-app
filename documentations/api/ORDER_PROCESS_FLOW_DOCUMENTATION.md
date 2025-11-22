# Order Process Flow Documentation

## Overview

This document provides comprehensive documentation for the order process flow **after checkout**, including all API endpoints, status transitions, role-specific workflows, and real-time updates.

**Base URL:** `/api/orders/`

**Authentication:** All endpoints require authentication (JWT token)

---

## Table of Contents

1. [Order Lifecycle Overview](#order-lifecycle-overview)
2. [Order Status Flow](#order-status-flow)
3. [API Endpoints](#api-endpoints)
4. [Role-Specific Workflows](#role-specific-workflows)
5. [Status Transitions](#status-transitions)
6. [Real-Time Updates](#real-time-updates)
7. [OTP Verification](#otp-verification)
8. [Order Cancellation](#order-cancellation)
9. [Order Tracking](#order-tracking)
10. [Code Examples](#code-examples)

---

## Order Lifecycle Overview

After an order is successfully placed through the checkout process, it goes through a series of status changes managed by different user roles:

```
Order Placed (Checkout)
    ↓
Payment Processing (if online)
    ↓
Restaurant Confirmation
    ↓
Food Preparation
    ↓
Ready for Pickup
    ↓
Delivery Partner Assignment
    ↓
Pickup Confirmation
    ↓
Out for Delivery
    ↓
Delivery & OTP Verification
    ↓
Order Delivered
```

---

## Order Status Flow

### Primary Status Sequence

```
ORDER_PLACED
  → ORDER_CONFIRMED / RESTAURANT_CONFIRMED
  → PREPARING / FOOD_BEING_PREPARED
  → DELIVERY_PARTNER_ASSIGNED
  → ORDER_READY_FOR_PICKUP
  → ORDER_PICKED_UP
  → OUT_FOR_DELIVERY
  → DELIVERED
```

### Payment Status Flow (Parallel)

```
PAYMENT_PENDING
  → PAYMENT_SUCCESS (if online payment)
  → ORDER_CONFIRMED
```

### Terminal States

- **CANCELLED**: Order cancelled by customer, restaurant, or system
- **REFUND_COMPLETED**: Refund processed after cancellation

---

## API Endpoints

### 1. Get Order Details

**Endpoint:** `GET /api/orders/{order_id}/`

**Method:** `GET`

**Authentication:** Required

**Description:** Retrieve complete order details including items, status, tracking, and delivery information.

**Response (200 OK):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "user": "990e8400-e29b-41d4-a716-446655440000",
  "user_name": "John Doe",
  "vendor": "550e8400-e29b-41d4-a716-446655440000",
  "vendor_name": "Pizza Palace",
  "order_status": "ORDER_CONFIRMED",
  "order_status_name": "Order Confirmed",
  "order_status_code": "ORDER_CONFIRMED",
  "delivery_status": "assigned",
  "delivery_person": "aa0e8400-e29b-41d4-a716-446655440000",
  "delivery_person_name": "Delivery Person",
  "delivery_address": {
    "id": 1,
    "title": "Home",
    "address_line_1": "123 Main Street"
  },
  "subtotal": "748.00",
  "delivery_fee": "25.00",
  "tax_amount": "37.40",
  "total_amount": "810.40",
  "payment_method": "cod",
  "payment_status": "pending",
  "order_placed_at": "2024-01-15T10:30:00Z",
  "estimated_delivery_time": "2024-01-15T12:15:00Z",
  "items": [...],
  "customer_latitude": "19.076000",
  "customer_longitude": "72.877700",
  "restaurant_latitude": "19.082000",
  "restaurant_longitude": "72.880000"
}
```

---

### 2. List Orders

**Endpoint:** `GET /api/orders/`

**Method:** `GET`

**Authentication:** Required

**Description:** Get list of orders for the authenticated user. Role-based filtering applies.

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | String | Filter by order status code |
| `include_cancelled` | Boolean | Include cancelled orders (default: false) |
| `page` | Integer | Page number for pagination |
| `page_size` | Integer | Items per page |

**Response (200 OK):**
```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "880e8400-e29b-41d4-a716-446655440000",
      "order_number": "ORD12345678",
      "order_status": "ORDER_CONFIRMED",
      "total_amount": "810.40",
      "order_placed_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

### 3. Update Order Status (Generic)

**Endpoint:** `POST /api/orders/{order_id}/status/`

**Method:** `POST`

**Authentication:** Required

**Description:** Generic endpoint to update order status. Validates status transitions.

**Request Body:**
```json
{
  "status_code": "ORDER_CONFIRMED",
  "reason": "Restaurant confirmed order",
  "metadata": {
    "estimated_prep_time": 20
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "previous_status": "ORDER_PLACED",
  "new_status": "ORDER_CONFIRMED",
  "status_name": "Order Confirmed",
  "tracking_id": "tracking-uuid",
  "message": "Order status updated successfully"
}
```

---

### 4. Restaurant: Confirm Order

**Endpoint:** `POST /api/restaurants/orders/{order_id}/confirm/`

**Method:** `POST`

**Authentication:** Required (Restaurant Owner)

**Description:** Restaurant confirms an order. Triggers delivery partner assignment.

**Request Body:**
```json
{
  "estimated_prep_time": 20
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "RESTAURANT_CONFIRMED",
  "estimated_ready_time": "2024-01-15T11:00:00Z",
  "message": "Order confirmed successfully"
}
```

**Status Transition:**
- From: `ORDER_PLACED`, `PAYMENT_SUCCESS`
- To: `RESTAURANT_CONFIRMED`

---

### 5. Restaurant: Start Preparing

**Endpoint:** `POST /api/restaurants/orders/{order_id}/start-preparing/`

**Method:** `POST`

**Authentication:** Required (Restaurant Owner)

**Description:** Restaurant starts preparing the order.

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "PREPARING",
  "message": "Order preparation started"
}
```

**Status Transition:**
- From: `RESTAURANT_CONFIRMED`, `ORDER_CONFIRMED`
- To: `PREPARING`

---

### 6. Restaurant: Mark Ready for Pickup

**Endpoint:** `POST /api/restaurants/orders/{order_id}/mark-ready/`

**Method:** `POST`

**Authentication:** Required (Restaurant Owner)

**Description:** Restaurant marks order ready for pickup. Triggers delivery partner notification.

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "READY_FOR_PICKUP",
  "ready_time": "2024-01-15T11:20:00Z",
  "message": "Order marked ready for pickup"
}
```

**Status Transition:**
- From: `PREPARING`, `FOOD_BEING_PREPARED`
- To: `READY_FOR_PICKUP`

**Triggers:**
- Delivery partner assignment (if not already assigned)
- Notification to delivery partner
- Event: `order.ready_for_pickup`

---

### 7. Restaurant: Get Order Queue

**Endpoint:** `GET /api/restaurants/orders/queue/`

**Method:** `GET`

**Authentication:** Required (Restaurant Owner)

**Description:** Get all active orders for the restaurant.

**Response (200 OK):**
```json
{
  "count": 5,
  "orders": [
    {
      "id": "880e8400-e29b-41d4-a716-446655440000",
      "order_number": "ORD12345678",
      "order_status": "PREPARING",
      "total_amount": "810.40",
      "order_placed_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

### 8. Delivery Partner: Pickup Order

**Endpoint:** `POST /api/orders/{order_id}/pickup/`

**Method:** `POST`

**Authentication:** Required (Delivery Person)

**Description:** Delivery partner confirms picking up the order from restaurant.

**Request Body:**
```json
{
  "otp": "123456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "ORDER_PICKED_UP",
  "message": "Order picked up successfully"
}
```

**Status Transition:**
- From: `READY_FOR_PICKUP`
- To: `ORDER_PICKED_UP`

**OTP Verification:**
- OTP is required for pickup verification
- OTP is generated when order is marked ready

---

### 9. Delivery Partner: Start Delivery

**Endpoint:** `POST /api/orders/{order_id}/start-delivery/`

**Method:** `POST`

**Authentication:** Required (Delivery Person)

**Description:** Delivery partner starts delivery to customer.

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "OUT_FOR_DELIVERY",
  "message": "Delivery started"
}
```

**Status Transition:**
- From: `ORDER_PICKED_UP`
- To: `OUT_FOR_DELIVERY`

---

### 10. Delivery Partner: Complete Delivery

**Endpoint:** `POST /api/orders/{order_id}/complete-delivery/`

**Method:** `POST`

**Authentication:** Required (Delivery Person)

**Description:** Delivery partner completes delivery. Requires OTP verification.

**Request Body:**
```json
{
  "otp": "654321",
  "delivery_notes": "Delivered to customer"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "DELIVERED",
  "actual_delivery_time": "2024-01-15T12:10:00Z",
  "message": "Order delivered successfully"
}
```

**Status Transition:**
- From: `OUT_FOR_DELIVERY`
- To: `DELIVERED`

**OTP Verification:**
- OTP is required for delivery completion
- OTP is sent to customer when delivery starts

---

### 11. Customer: Cancel Order

**Endpoint:** `POST /api/orders/{order_id}/cancel/`

**Method:** `POST`

**Authentication:** Required

**Description:** Customer cancels their order. Triggers refund if payment completed.

**Request Body:**
```json
{
  "reason": "Changed my mind"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "status": "CANCELLED",
  "refund_status": "pending",
  "message": "Order cancelled successfully"
}
```

**Status Transition:**
- From: Any active status
- To: `CANCELLED`

**Refund Processing:**
- If payment completed: Automatic refund initiated
- If COD: No refund needed
- Refund status updated when processed

---

### 12. Get Order OTP

**Endpoint:** `GET /api/orders/{order_id}/otp/`

**Method:** `GET`

**Authentication:** Required

**Description:** Get OTP for order verification (pickup or delivery).

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `type` | String | `pickup` or `delivery` (default: `delivery`) |

**Response (200 OK):**
```json
{
  "otp": "123456",
  "type": "delivery",
  "expires_at": "2024-01-15T12:30:00Z",
  "order_id": "880e8400-e29b-41d4-a716-446655440000"
}
```

**Note:** OTP is only returned to authorized users (restaurant for pickup, customer for delivery).

---

### 13. Verify OTP

**Endpoint:** `POST /api/orders/{order_id}/otp/verify/`

**Method:** `POST`

**Authentication:** Required

**Description:** Verify OTP for order verification.

**Request Body:**
```json
{
  "otp": "123456",
  "type": "delivery"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "verified": true,
  "message": "OTP verified successfully"
}
```

---

### 14. Get Order Status History

**Endpoint:** `GET /api/orders/{order_id}/history/`

**Method:** `GET`

**Authentication:** Required

**Description:** Get complete status history and tracking events for an order.

**Response (200 OK):**
```json
{
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "history": [
    {
      "id": "tracking-uuid",
      "status": "ORDER_PLACED",
      "status_name": "Order Placed",
      "description": "Order placed by customer",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_by": "Customer Name"
    },
    {
      "id": "tracking-uuid-2",
      "status": "ORDER_CONFIRMED",
      "status_name": "Order Confirmed",
      "description": "Restaurant confirmed order",
      "created_at": "2024-01-15T10:35:00Z",
      "updated_by": "Restaurant Name"
    }
  ]
}
```

---

### 15. Get Order ETA

**Endpoint:** `GET /api/orders/{order_id}/eta/`

**Method:** `GET`

**Authentication:** Required

**Description:** Get estimated delivery time and current ETA.

**Response (200 OK):**
```json
{
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "estimated_delivery_time": "2024-01-15T12:15:00Z",
  "current_eta_minutes": 25,
  "status": "OUT_FOR_DELIVERY",
  "delivery_person_location": {
    "latitude": "19.080000",
    "longitude": "72.879000"
  },
  "customer_location": {
    "latitude": "19.076000",
    "longitude": "72.877700"
  }
}
```

---

## Role-Specific Workflows

### Customer Workflow

#### 1. Order Placed
- **Status:** `ORDER_PLACED`
- **Action:** Order created via checkout
- **API:** `POST /api/orders/`
- **Next:** Wait for restaurant confirmation

#### 2. Order Confirmed
- **Status:** `ORDER_CONFIRMED` / `RESTAURANT_CONFIRMED`
- **Action:** Restaurant confirms order
- **Notification:** Customer receives confirmation
- **Next:** Wait for preparation

#### 3. Food Being Prepared
- **Status:** `PREPARING` / `FOOD_BEING_PREPARED`
- **Action:** Restaurant starts preparing
- **Notification:** Customer notified
- **Next:** Wait for ready status

#### 4. Ready for Pickup
- **Status:** `READY_FOR_PICKUP`
- **Action:** Restaurant marks ready
- **Notification:** Customer notified
- **Next:** Wait for delivery partner pickup

#### 5. Out for Delivery
- **Status:** `OUT_FOR_DELIVERY`
- **Action:** Delivery partner starts delivery
- **Notification:** Customer receives OTP
- **Real-Time:** Live tracking available
- **Next:** Wait for delivery

#### 6. Order Delivered
- **Status:** `DELIVERED`
- **Action:** Delivery partner completes delivery with OTP
- **Notification:** Customer receives delivery confirmation
- **Next:** Order complete, can rate/review

**Customer Actions:**
- `GET /api/orders/{order_id}/` - View order details
- `GET /api/orders/` - List all orders
- `POST /api/orders/{order_id}/cancel/` - Cancel order
- `GET /api/orders/{order_id}/otp/` - Get delivery OTP
- `GET /api/orders/{order_id}/history/` - View order history
- `GET /api/orders/{order_id}/eta/` - Get delivery ETA

---

### Restaurant (Vendor) Workflow

#### 1. Receive Order
- **Status:** `ORDER_PLACED`
- **Action:** Order notification received
- **API:** `GET /api/restaurants/orders/queue/`
- **Next:** Accept or reject order

#### 2. Confirm Order
- **Status:** `RESTAURANT_CONFIRMED`
- **Action:** Restaurant confirms order
- **API:** `POST /api/restaurants/orders/{order_id}/confirm/`
- **Triggers:** Delivery partner assignment
- **Next:** Start preparation

#### 3. Start Preparing
- **Status:** `PREPARING`
- **Action:** Restaurant starts preparing
- **API:** `POST /api/restaurants/orders/{order_id}/start-preparing/`
- **Next:** Continue preparation

#### 4. Mark Ready
- **Status:** `READY_FOR_PICKUP`
- **Action:** Restaurant marks order ready
- **API:** `POST /api/restaurants/orders/{order_id}/mark-ready/`
- **Triggers:** 
  - Pickup OTP generation
  - Delivery partner notification
  - Event: `order.ready_for_pickup`
- **Next:** Wait for pickup

#### 5. Order Picked Up
- **Status:** `ORDER_PICKED_UP`
- **Action:** Delivery partner confirms pickup
- **Notification:** Restaurant notified
- **Next:** Order in transit

**Restaurant Actions:**
- `GET /api/restaurants/orders/queue/` - View order queue
- `POST /api/restaurants/orders/{order_id}/confirm/` - Confirm order
- `POST /api/restaurants/orders/{order_id}/start-preparing/` - Start preparation
- `POST /api/restaurants/orders/{order_id}/mark-ready/` - Mark ready
- `GET /api/orders/{order_id}/otp/` - Get pickup OTP

---

### Delivery Partner Workflow

#### 1. Receive Assignment
- **Status:** `DELIVERY_PARTNER_ASSIGNED`
- **Action:** Automatically assigned when order confirmed
- **Notification:** Delivery partner receives assignment
- **Next:** Navigate to restaurant

#### 2. Navigate to Restaurant
- **Status:** `DELIVERY_PARTNER_ASSIGNED` or `READY_FOR_PICKUP`
- **Action:** Use restaurant coordinates for navigation
- **API:** `GET /api/orders/{order_id}/` - Get restaurant location
- **Next:** Arrive at restaurant

#### 3. Pickup Order
- **Status:** `ORDER_PICKED_UP`
- **Action:** Confirm pickup with OTP
- **API:** `POST /api/orders/{order_id}/pickup/`
- **OTP:** Required from restaurant
- **Next:** Start delivery

#### 4. Start Delivery
- **Status:** `OUT_FOR_DELIVERY`
- **Action:** Start delivery to customer
- **API:** `POST /api/orders/{order_id}/start-delivery/`
- **Triggers:** 
  - Delivery OTP sent to customer
  - Real-time tracking enabled
- **Next:** Navigate to customer

#### 5. Complete Delivery
- **Status:** `DELIVERED`
- **Action:** Complete delivery with OTP verification
- **API:** `POST /api/orders/{order_id}/complete-delivery/`
- **OTP:** Required from customer
- **Next:** Order complete

**Delivery Partner Actions:**
- `GET /api/orders/available/` - View available orders
- `GET /api/orders/{order_id}/` - Get order details
- `POST /api/orders/{order_id}/pickup/` - Confirm pickup
- `POST /api/orders/{order_id}/start-delivery/` - Start delivery
- `POST /api/orders/{order_id}/complete-delivery/` - Complete delivery

---

## Status Transitions

### Valid Status Transitions

| Current Status | Valid Next Statuses |
|----------------|---------------------|
| `ORDER_PLACED` | `ORDER_CONFIRMED`, `RESTAURANT_CONFIRMED`, `CANCELLED` |
| `PAYMENT_PENDING` | `PAYMENT_SUCCESS`, `PAYMENT_FAILED`, `CANCELLED` |
| `PAYMENT_SUCCESS` | `RESTAURANT_CONFIRMED`, `RESTAURANT_REJECTED`, `CANCELLED` |
| `ORDER_CONFIRMED` | `PREPARING`, `CANCELLED` |
| `RESTAURANT_CONFIRMED` | `PREPARING`, `CANCELLED` |
| `PREPARING` | `READY_FOR_PICKUP`, `CANCELLED` |
| `FOOD_BEING_PREPARED` | `READY_FOR_PICKUP`, `CANCELLED` |
| `READY_FOR_PICKUP` | `ORDER_PICKED_UP`, `CANCELLED` |
| `ORDER_PICKED_UP` | `OUT_FOR_DELIVERY`, `CANCELLED` |
| `OUT_FOR_DELIVERY` | `DELIVERED`, `CANCELLED` |
| `DELIVERED` | (Terminal state) |
| `CANCELLED` | `REFUND_COMPLETED` (if payment completed) |

### Status Transition Rules

1. **Sequential Flow:** Most statuses must follow the sequence
2. **Role-Based:** Only authorized roles can trigger specific transitions
3. **Validation:** Backend validates all transitions
4. **Tracking:** All transitions are logged in OrderTracking
5. **Events:** Status changes trigger events for real-time updates

---

## Real-Time Updates

### WebSocket Events

Orders support real-time updates via WebSocket connections:

**Event Types:**
- `order.status_changed` - Order status updated
- `order.assigned` - Delivery partner assigned
- `order.ready_for_pickup` - Order ready for pickup
- `order.picked_up` - Order picked up
- `order.out_for_delivery` - Order out for delivery
- `order.delivered` - Order delivered
- `order.cancelled` - Order cancelled

**Event Payload:**
```json
{
  "event_type": "order.status_changed",
  "order_id": "880e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD12345678",
  "previous_status": "ORDER_PLACED",
  "new_status": "ORDER_CONFIRMED",
  "status_name": "Order Confirmed",
  "timestamp": "2024-01-15T10:35:00Z",
  "updated_by": "Restaurant Name"
}
```

**WebSocket Connection:**
```
ws://localhost:8000/ws/orders/{order_id}/
```

---

## OTP Verification

### Pickup OTP

**Generated When:** Order marked ready for pickup
**Sent To:** Restaurant
**Used By:** Delivery partner for pickup verification
**Valid For:** 15 minutes

**Flow:**
1. Restaurant marks order ready
2. Pickup OTP generated
3. Restaurant receives OTP
4. Delivery partner requests OTP
5. Delivery partner verifies OTP on pickup

### Delivery OTP

**Generated When:** Delivery partner starts delivery
**Sent To:** Customer
**Used By:** Delivery partner for delivery verification
**Valid For:** 30 minutes

**Flow:**
1. Delivery partner starts delivery
2. Delivery OTP generated and sent to customer
3. Customer receives OTP via SMS/notification
4. Delivery partner requests OTP from customer
5. Delivery partner verifies OTP on delivery

**OTP Endpoints:**
- `GET /api/orders/{order_id}/otp/` - Get OTP
- `POST /api/orders/{order_id}/otp/verify/` - Verify OTP
- `POST /api/orders/{order_id}/otp/resend/` - Resend OTP

---

## Order Cancellation

### Cancellation Rules

1. **Customer Cancellation:**
   - Can cancel if status is `ORDER_PLACED` or `ORDER_CONFIRMED`
   - Cannot cancel if order is being prepared or delivered
   - Refund processed if payment completed

2. **Restaurant Cancellation:**
   - Can cancel if order not yet picked up
   - Must provide reason
   - Refund processed automatically

3. **System Cancellation:**
   - Auto-cancellation if restaurant doesn't confirm within time limit
   - Auto-cancellation if delivery partner doesn't pick up within time limit

### Refund Processing

**Automatic Refund:**
- Online payments: Processed via payment gateway
- COD: No refund needed
- Refund status: `pending` → `processing` → `completed`

**Refund Status:**
- `pending` - Refund initiated
- `processing` - Refund being processed
- `completed` - Refund completed
- `failed` - Refund failed (manual intervention required)

---

## Order Tracking

### Tracking Events

Every status change creates a tracking event:

```json
{
  "id": "tracking-uuid",
  "order": "order-uuid",
  "status": "ORDER_CONFIRMED",
  "description": "Restaurant confirmed order",
  "created_at": "2024-01-15T10:35:00Z",
  "updated_by": "Restaurant Name",
  "metadata": {
    "estimated_prep_time": 20
  }
}
```

### Location Tracking

**GPS Coordinates:**
- `customer_latitude` / `customer_longitude` - Customer location
- `restaurant_latitude` / `restaurant_longitude` - Restaurant location
- `current_latitude` / `current_longitude` - Delivery partner current location

**Real-Time Updates:**
- Delivery partner location updated every 30 seconds
- Customer can view live tracking on map
- ETA recalculated based on current location

---

## Code Examples

### JavaScript/React Example

```javascript
// Order Service
class OrderService {
  constructor(apiClient) {
    this.api = apiClient;
  }

  // Get order details
  async getOrder(orderId) {
    return await this.api.get(`/api/orders/${orderId}/`);
  }

  // List orders
  async listOrders(filters = {}) {
    const params = new URLSearchParams(filters);
    return await this.api.get(`/api/orders/?${params}`);
  }

  // Cancel order
  async cancelOrder(orderId, reason) {
    return await this.api.post(`/api/orders/${orderId}/cancel/`, {
      reason
    });
  }

  // Get order history
  async getOrderHistory(orderId) {
    return await this.api.get(`/api/orders/${orderId}/history/`);
  }

  // Get order ETA
  async getOrderETA(orderId) {
    return await this.api.get(`/api/orders/${orderId}/eta/`);
  }

  // Get delivery OTP
  async getDeliveryOTP(orderId) {
    return await this.api.get(`/api/orders/${orderId}/otp/?type=delivery`);
  }
}

// Restaurant Service
class RestaurantService {
  constructor(apiClient) {
    this.api = apiClient;
  }

  // Get order queue
  async getOrderQueue() {
    return await this.api.get('/api/restaurants/orders/queue/');
  }

  // Confirm order
  async confirmOrder(orderId, estimatedPrepTime = 20) {
    return await this.api.post(`/api/restaurants/orders/${orderId}/confirm/`, {
      estimated_prep_time: estimatedPrepTime
    });
  }

  // Start preparing
  async startPreparing(orderId) {
    return await this.api.post(`/api/restaurants/orders/${orderId}/start-preparing/`);
  }

  // Mark ready
  async markReady(orderId) {
    return await this.api.post(`/api/restaurants/orders/${orderId}/mark-ready/`);
  }
}

// Delivery Service
class DeliveryService {
  constructor(apiClient) {
    this.api = apiClient;
  }

  // Get available orders
  async getAvailableOrders() {
    return await this.api.get('/api/orders/available/');
  }

  // Pickup order
  async pickupOrder(orderId, otp) {
    return await this.api.post(`/api/orders/${orderId}/pickup/`, {
      otp
    });
  }

  // Start delivery
  async startDelivery(orderId) {
    return await this.api.post(`/api/orders/${orderId}/start-delivery/`);
  }

  // Complete delivery
  async completeDelivery(orderId, otp, deliveryNotes) {
    return await this.api.post(`/api/orders/${orderId}/complete-delivery/`, {
      otp,
      delivery_notes: deliveryNotes
    });
  }
}

// Usage Example
const orderService = new OrderService(apiClient);

// Customer: Track order
const order = await orderService.getOrder(orderId);
console.log(`Order status: ${order.order_status}`);

// Restaurant: Process order
const restaurantService = new RestaurantService(apiClient);
await restaurantService.confirmOrder(orderId, 20);
await restaurantService.startPreparing(orderId);
await restaurantService.markReady(orderId);

// Delivery: Deliver order
const deliveryService = new DeliveryService(apiClient);
const availableOrders = await deliveryService.getAvailableOrders();
await deliveryService.pickupOrder(orderId, pickupOTP);
await deliveryService.startDelivery(orderId);
await deliveryService.completeDelivery(orderId, deliveryOTP, "Delivered successfully");
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
    
    def get_order(self, order_id):
        url = f'{self.base_url}/api/orders/{order_id}/'
        response = requests.get(url, headers=self.headers)
        return response.json()
    
    def list_orders(self, **filters):
        url = f'{self.base_url}/api/orders/'
        response = requests.get(url, headers=self.headers, params=filters)
        return response.json()
    
    def cancel_order(self, order_id, reason):
        url = f'{self.base_url}/api/orders/{order_id}/cancel/'
        response = requests.post(url, headers=self.headers, json={'reason': reason})
        return response.json()
    
    def get_order_history(self, order_id):
        url = f'{self.base_url}/api/orders/{order_id}/history/'
        response = requests.get(url, headers=self.headers)
        return response.json()

class RestaurantAPI:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def get_order_queue(self):
        url = f'{self.base_url}/api/restaurants/orders/queue/'
        response = requests.get(url, headers=self.headers)
        return response.json()
    
    def confirm_order(self, order_id, estimated_prep_time=20):
        url = f'{self.base_url}/api/restaurants/orders/{order_id}/confirm/'
        response = requests.post(url, headers=self.headers, json={
            'estimated_prep_time': estimated_prep_time
        })
        return response.json()
    
    def start_preparing(self, order_id):
        url = f'{self.base_url}/api/restaurants/orders/{order_id}/start-preparing/'
        response = requests.post(url, headers=self.headers)
        return response.json()
    
    def mark_ready(self, order_id):
        url = f'{self.base_url}/api/restaurants/orders/{order_id}/mark-ready/'
        response = requests.post(url, headers=self.headers)
        return response.json()

# Usage
order_api = OrderAPI('http://localhost:8000', 'your_token')
order = order_api.get_order('order-uuid')
print(f"Order status: {order['order_status']}")

restaurant_api = RestaurantAPI('http://localhost:8000', 'restaurant_token')
queue = restaurant_api.get_order_queue()
for order in queue['orders']:
    restaurant_api.confirm_order(order['id'], 20)
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

  // Get order details
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load order');
  }

  // List orders
  Future<Map<String, dynamic>> listOrders({Map<String, String>? filters}) async {
    String url = '$baseUrl/api/orders/';
    if (filters != null && filters.isNotEmpty) {
      url += '?${Uri(queryParameters: filters).query}';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load orders');
  }

  // Cancel order
  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/cancel/'),
      headers: headers,
      body: json.encode({'reason': reason}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to cancel order');
  }

  // Get order history
  Future<Map<String, dynamic>> getOrderHistory(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId/history/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load order history');
  }
}

// Usage
final orderService = OrderService('http://localhost:8000', 'your_token');

// Get order
final order = await orderService.getOrder('order-uuid');
print('Order status: ${order['order_status']}');

// List orders
final orders = await orderService.listOrders(
  filters: {'status': 'ORDER_CONFIRMED'}
);

// Cancel order
await orderService.cancelOrder('order-uuid', 'Changed my mind');
```

---

## Best Practices

### 1. Status Polling

- **Don't:** Poll order status every second
- **Do:** Use WebSocket for real-time updates
- **Do:** Poll every 10-30 seconds if WebSocket unavailable
- **Do:** Poll immediately after status-changing actions

### 2. Error Handling

- **Handle 404:** Order not found or access denied
- **Handle 400:** Invalid status transition
- **Handle 403:** Insufficient permissions
- **Handle 500:** Server error, retry with exponential backoff

### 3. OTP Management

- **Store OTP securely:** Don't log or expose OTPs
- **Handle expiration:** Check OTP expiry before use
- **Resend OTP:** Provide resend option if expired
- **Validate format:** Ensure OTP is 6 digits

### 4. Real-Time Updates

- **WebSocket:** Use for live tracking
- **Fallback:** Poll API if WebSocket unavailable
- **Reconnect:** Implement automatic reconnection
- **Handle disconnects:** Gracefully handle connection loss

### 5. Order Cancellation

- **Check status:** Verify order can be cancelled
- **Show confirmation:** Require user confirmation
- **Handle refunds:** Inform user about refund process
- **Update UI:** Immediately update UI after cancellation

---

## Summary

The order process flow after checkout involves:

- ✅ **Multiple status transitions** managed by different roles
- ✅ **Real-time updates** via WebSocket
- ✅ **OTP verification** for pickup and delivery
- ✅ **Automatic delivery partner assignment**
- ✅ **Order tracking** with GPS coordinates
- ✅ **Cancellation and refund** handling
- ✅ **Complete audit trail** via order history

**Key Endpoints:**
- `GET /api/orders/{order_id}/` - Get order details
- `POST /api/restaurants/orders/{order_id}/confirm/` - Restaurant confirms
- `POST /api/restaurants/orders/{order_id}/mark-ready/` - Mark ready
- `POST /api/orders/{order_id}/pickup/` - Delivery partner picks up
- `POST /api/orders/{order_id}/complete-delivery/` - Complete delivery
- `POST /api/orders/{order_id}/cancel/` - Cancel order

**Important Notes:**
- Status transitions are validated and sequential
- OTP is required for pickup and delivery
- Real-time updates available via WebSocket
- GPS coordinates used for live tracking
- Refunds processed automatically for online payments

