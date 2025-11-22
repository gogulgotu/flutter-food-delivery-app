# Delivery Person Role Documentation

## Overview

This document provides comprehensive documentation for all screens, functionalities, and API endpoints available to **Delivery Person** users in the Flutter application. Delivery persons can manage their delivery operations, accept/reject orders, track deliveries, navigate to locations, verify pickups and deliveries, view earnings, and manage their profile.

---

## Table of Contents

1. [Authentication Screens](#authentication-screens)
2. [Dashboard Screens](#dashboard-screens)
3. [Order Acceptance Screens](#order-acceptance-screens)
4. [Order Management Screens](#order-management-screens)
5. [Navigation Screens](#navigation-screens)
6. [Earnings & History Screens](#earnings--history-screens)
7. [Profile & Support Screens](#profile--support-screens)

---

## Authentication Screens

### 1. Login Screen

**Purpose/Functionality:**
- Allows delivery persons to authenticate using mobile number and OTP or email/password
- Validates delivery person account status
- Ensures user has delivery person role

**User Actions:**
- Enter mobile number or email
- Select authentication method (OTP or Password)
- Tap "Send OTP" or "Login" button
- Navigate to OTP verification screen (if OTP selected)

**API Endpoints:**

#### Send OTP
- **Method:** `POST`
- **Endpoint:** `/api/auth/send-otp/`
- **Authentication:** Not required
- **Request Body:**
  ```json
  {
    "mobile_number": "+919876543210"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "OTP sent successfully",
    "otp": "123456",  // Only in development
    "expires_in": 300
  }
  ```

#### Login with Credentials
- **Method:** `POST`
- **Endpoint:** `/api/auth/login-user/`
- **Authentication:** Not required
- **Request Body:**
  ```json
  {
    "email": "delivery@example.com",
    "password": "password123"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
      "id": "uuid",
      "email": "delivery@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "user_role_name": "Delivery Person"
    }
  }
  ```

**Error Handling:**
- Display error for invalid credentials
- Check if user has delivery person role
- Validate delivery person account status
- Handle network errors

---

### 2. OTP Verification Screen

**Purpose/Functionality:**
- Verifies OTP sent to delivery person's mobile number
- Completes authentication and returns JWT tokens

**User Actions:**
- Enter 6-digit OTP
- Tap "Verify OTP" button
- Request resend OTP if needed

**API Endpoints:**

#### Verify OTP
- **Method:** `POST`
- **Endpoint:** `/api/auth/verify-otp/`
- **Authentication:** Not required
- **Request Body:**
  ```json
  {
    "mobile_number": "+919876543210",
    "otp": "123456"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "OTP verified successfully",
    "user_type": "existing",
    "user": {
      "id": "uuid",
      "phone_number": "+919876543210",
      "first_name": "John",
      "last_name": "Doe",
      "user_role_name": "Delivery Person"
    },
    "tokens": {
      "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
      "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
    }
  }
  ```

**Error Handling:**
- Display error for invalid/expired OTP
- Show countdown timer for OTP expiry
- Enable resend OTP after 60 seconds

---

## Dashboard Screens

### 3. Delivery Dashboard Screen

**Purpose/Functionality:**
- Main dashboard showing key metrics and active orders
- Displays today's stats (deliveries, earnings, distance, hours online)
- Shows active assignments and cancelled orders
- Provides quick access to toggle online status

**User Actions:**
- View dashboard statistics
- Toggle online/offline status
- View active assignments
- Check today's earnings and deliveries
- View weekly stats
- Access order details

**API Endpoints:**

#### Get Delivery Dashboard
- **Method:** `GET`
- **Endpoint:** `/api/delivery/dashboard/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "delivery_person": {
      "id": "uuid",
      "user_name": "John Doe",
      "rating": 4.8,
      "total_deliveries": 150,
      "phone": "+919876543210",
      "vehicle_type": "Bike",
      "vehicle_number": "MH-01-AB-1234"
    },
    "is_online": true,
    "current_shift": {
      "id": "uuid",
      "shift_date": "2024-01-15",
      "start_time": "2024-01-15T08:00:00Z",
      "end_time": null,
      "is_active": true,
      "total_deliveries": 5,
      "total_earnings": 500.00,
      "total_distance_km": 25.5
    },
    "active_assignments": [
      {
        "id": "uuid",
        "order": {
          "id": "uuid",
          "order_number": "ORD-2024-001",
          "vendor": {
            "name": "Pizza Palace",
            "address": "123 Food Street"
          },
          "delivery_address": {
            "address_line_1": "456 Customer St",
            "city": "Mumbai"
          },
          "total_amount": 623.00
        },
        "status": "accepted",
        "estimated_earnings": 50.00
      }
    ],
    "cancelled_assignments": [],
    "today_stats": {
      "deliveries": 5,
      "earnings": 500.00,
      "distance_km": 25.5,
      "hours_online": 8.5
    },
    "weekly_stats": {
      "deliveries": 35,
      "earnings": 3500.00,
      "distance_km": 175.0,
      "days_active": 5
    },
    "performance_metrics": {
      "on_time_delivery_rate": 95.0,
      "average_delivery_time": 25,
      "customer_rating": 4.8
    },
    "pending_earnings": 500.00,
    "total_earnings": 15000.00
  }
  ```
- **Error Responses:**
  - `403 Forbidden`: User is not a delivery person
  - `500 Internal Server Error`: Server error

**Error Handling:**
- Handle missing delivery profile
- Display error if profile not set up
- Show loading state during data fetch

---

### 4. Toggle Online Status

**Purpose/Functionality:**
- Allows delivery person to go online/offline
- Automatically starts/ends delivery shift
- Controls whether delivery person receives new order assignments

**User Actions:**
- Toggle online/offline switch
- Confirm status change
- View current shift information

**API Endpoints:**

#### Toggle Online Status
- **Method:** `POST`
- **Endpoint:** `/api/delivery/toggle-online/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "is_online": true
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "is_online": true,
    "message": "Status updated successfully"
  }
  ```
- **Note:** When going online, a new shift is automatically created if none exists. When going offline, the current shift is ended.

**Error Handling:**
- Handle status update errors
- Display confirmation messages
- Show shift creation errors

---

### 5. Update Location

**Purpose/Functionality:**
- Updates delivery person's GPS location in real-time
- Used for tracking and navigation
- Can be associated with a specific assignment

**User Actions:**
- Enable location tracking
- Update location automatically (background)
- Manually update location
- View current location on map

**API Endpoints:**

#### Update Location
- **Method:** `POST`
- **Endpoint:** `/api/delivery/update-location/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "latitude": 19.0760,
    "longitude": 72.8777,
    "accuracy": 10.5,
    "speed": 25.0,
    "heading": 90.0,
    "assignment_id": "uuid"  // Optional: associate with specific assignment
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Location updated successfully",
    "latitude": 19.0760,
    "longitude": 72.8777
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Missing latitude or longitude
  - `500 Internal Server Error`: Server error

**Error Handling:**
- Validate GPS coordinates
- Handle location permission errors
- Display location update errors
- Handle offline scenarios

---

## Order Acceptance Screens

### 6. Available Orders Screen

**Purpose/Functionality:**
- Displays new orders available for acceptance
- Shows order details, distance, and estimated earnings
- Allows accepting or rejecting orders

**User Actions:**
- View available orders list
- View order details
- Accept order
- Reject order with reason
- Refresh available orders

**API Endpoints:**

#### Get Available Orders
- **Method:** `GET`
- **Endpoint:** `/api/orders/available/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  [
    {
      "id": "uuid",
      "order_number": "ORD-2024-001",
      "vendor": {
        "id": "uuid",
        "name": "Pizza Palace",
        "address": "123 Food Street",
        "latitude": 19.0760,
        "longitude": 72.8777
      },
      "delivery_address": {
        "address_line_1": "456 Customer St",
        "city": "Mumbai",
        "latitude": 19.2183,
        "longitude": 72.9781
      },
      "total_amount": 623.00,
      "estimated_earnings": 50.00,
      "estimated_distance_km": 5.2,
      "estimated_delivery_time": "2024-01-15T12:30:00Z",
      "order_placed_at": "2024-01-15T10:30:00Z"
    }
  ]
  ```

#### Accept Available Order
- **Method:** `POST`
- **Endpoint:** `/api/delivery/orders/{order_id}/accept/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "message": "Order accepted successfully",
    "assignment": {
      "id": "uuid",
      "order": {
        "id": "uuid",
        "order_number": "ORD-2024-001"
      },
      "status": "accepted"
    }
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Order already assigned or not available
  - `404 Not Found`: Order not found

**Error Handling:**
- Handle order already assigned
- Display order acceptance errors
- Show order unavailability messages

---

### 7. Order Assignments Screen

**Purpose/Functionality:**
- Displays pending order assignments
- Shows assignments that need acceptance/rejection
- Provides quick actions for assignments

**User Actions:**
- View pending assignments
- Accept assignment
- Reject assignment with reason
- View assignment details

**API Endpoints:**

#### Get Order Assignments
- **Method:** `GET`
- **Endpoint:** `/api/delivery/assignments/`
- **Authentication:** Required (Delivery Person)
- **Query Parameters:**
  - `status`: Filter by status (`pending`, `accepted`, `in_progress`, `completed`, `cancelled`)
- **Response (200 OK):**
  ```json
  [
    {
      "id": "uuid",
      "order": {
        "id": "uuid",
        "order_number": "ORD-2024-001",
        "vendor": {
          "name": "Pizza Palace",
          "address": "123 Food Street"
        },
        "delivery_address": {
          "address_line_1": "456 Customer St",
          "city": "Mumbai"
        },
        "total_amount": 623.00
      },
      "status": "pending",
      "estimated_earnings": 50.00,
      "created_on": "2024-01-15T10:30:00Z"
    }
  ]
  ```

#### Accept Assignment
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/accept/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "status": "accepted",
    "accepted_at": "2024-01-15T10:35:00Z",
    "order": {
      "id": "uuid",
      "order_number": "ORD-2024-001"
    }
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Assignment already accepted or not pending
  - `404 Not Found`: Assignment not found

#### Reject Assignment
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/reject/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "rejection_reason": "Too far from current location"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Order rejected successfully",
    "assignment_id": "uuid"
  }
  ```

**Error Handling:**
- Handle assignment not found
- Validate assignment status
- Display rejection reason errors

---

## Order Management Screens

### 8. Order Detail Screen

**Purpose/Functionality:**
- Shows comprehensive order information
- Displays order items, customer details, addresses
- Provides order action buttons (arrived, verify pickup/delivery)
- Shows order timeline and status

**User Actions:**
- View order details
- View customer information
- View restaurant and delivery addresses
- Mark arrived at restaurant
- Verify pickup with OTP
- Mark arrived at customer
- Verify delivery with OTP
- Cancel order (if allowed)
- Contact customer or restaurant

**API Endpoints:**

#### Get Order Detail
- **Method:** `GET`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "order": {
      "id": "uuid",
      "order_number": "ORD-2024-001",
      "vendor": {
        "id": "uuid",
        "name": "Pizza Palace",
        "address": "123 Food Street",
        "phone": "+919876543210",
        "latitude": 19.0760,
        "longitude": 72.8777
      },
      "customer": {
        "id": "uuid",
        "first_name": "John",
        "last_name": "Doe",
        "phone": "+919876543211"
      },
      "delivery_address": {
        "title": "Home",
        "address_line_1": "456 Customer St",
        "city": "Mumbai",
        "postal_code": "400001",
        "latitude": 19.2183,
        "longitude": 72.9781
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
      "order_status": "ready",
      "payment_status": "completed",
      "delivery_status": "out_for_pickup",
      "estimated_delivery_time": "2024-01-15T12:30:00Z",
      "special_instructions": "Please ring the doorbell"
    },
    "status": "accepted",
    "estimated_earnings": 50.00,
    "accepted_at": "2024-01-15T10:35:00Z"
  }
  ```

**Error Handling:**
- Handle assignment not found
- Display order details errors
- Show permission errors

---

### 9. Mark Arrived at Restaurant

**Purpose/Functionality:**
- Marks delivery person's arrival at restaurant
- Updates order status
- Enables pickup verification

**User Actions:**
- Tap "Arrived at Restaurant" button
- Confirm arrival
- View restaurant location

**API Endpoints:**

#### Mark Arrived at Restaurant
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/arrived-restaurant/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "message": "Arrival at restaurant recorded",
    "assignment": {
      "id": "uuid",
      "status": "in_progress",
      "arrived_at_restaurant_at": "2024-01-15T11:00:00Z"
    }
  }
  ```

**Error Handling:**
- Handle assignment not found
- Validate assignment status
- Display arrival errors

---

### 10. Verify Pickup

**Purpose/Functionality:**
- Verifies order pickup from restaurant using OTP
- Completes pickup process
- Updates order status to out for delivery

**User Actions:**
- Enter OTP received from restaurant
- Verify pickup
- View pickup confirmation

**API Endpoints:**

#### Verify Pickup
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/verify-pickup/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "otp": "123456",
    "notes": "Order picked up successfully"  // Optional
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Pickup verified successfully",
    "assignment": {
      "id": "uuid",
      "status": "in_progress",
      "picked_up_at": "2024-01-15T11:05:00Z"
    },
    "order": {
      "delivery_status": "out_for_delivery"
    }
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Invalid OTP
  - `404 Not Found`: Assignment not found

**Error Handling:**
- Validate OTP format
- Handle invalid OTP errors
- Display pickup verification errors

---

### 11. Mark Arrived at Customer

**Purpose/Functionality:**
- Marks delivery person's arrival at customer location
- Updates order status
- Enables delivery verification

**User Actions:**
- Tap "Arrived at Customer" button
- Confirm arrival
- View customer location

**API Endpoints:**

#### Mark Arrived at Customer
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/arrived-customer/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "message": "Arrival at customer recorded",
    "assignment": {
      "id": "uuid",
      "status": "in_progress",
      "arrived_at_customer_at": "2024-01-15T12:00:00Z"
    }
  }
  ```

**Error Handling:**
- Handle assignment not found
- Validate assignment status
- Display arrival errors

---

### 12. Verify Delivery

**Purpose/Functionality:**
- Verifies order delivery to customer using OTP
- Completes delivery process
- Updates order status to delivered
- Calculates earnings

**User Actions:**
- Enter OTP received from customer
- Verify delivery
- View delivery confirmation
- View earnings for delivery

**API Endpoints:**

#### Verify Delivery
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/verify-delivery/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "otp": "123456",
    "notes": "Delivered successfully"  // Optional
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Delivery verified successfully",
    "assignment": {
      "id": "uuid",
      "status": "completed",
      "delivered_at": "2024-01-15T12:05:00Z",
      "earnings": 50.00
    },
    "order": {
      "delivery_status": "delivered",
      "order_status": "delivered"
    }
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Invalid OTP
  - `404 Not Found`: Assignment not found

**Error Handling:**
- Validate OTP format
- Handle invalid OTP errors
- Display delivery verification errors
- Show earnings calculation errors

---

### 13. Cancel Order

**Purpose/Functionality:**
- Allows delivery person to cancel an assignment
- Requires cancellation reason
- Updates order status

**User Actions:**
- Select cancel order option
- Enter cancellation reason
- Confirm cancellation

**API Endpoints:**

#### Cancel Order
- **Method:** `POST`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/cancel/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "cancellation_reason": "Customer not available"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Order cancelled successfully",
    "assignment_id": "uuid"
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Cannot cancel completed order
  - `404 Not Found`: Assignment not found

**Error Handling:**
- Validate cancellation eligibility
- Require cancellation reason
- Display cancellation errors

---

## Navigation Screens

### 14. Restaurant Navigation Screen

**Purpose/Functionality:**
- Provides navigation to restaurant location
- Shows map with route to restaurant
- Displays estimated arrival time
- Updates location in real-time

**User Actions:**
- View map with restaurant location
- Start navigation to restaurant
- View route and distance
- Update location
- Mark arrived at restaurant

**API Endpoints:**

#### Get Order Detail (for navigation)
- **Method:** `GET`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/`
- **Authentication:** Required (Delivery Person)
- **Response:** Same as Order Detail endpoint

#### Update Location
- **Method:** `POST`
- **Endpoint:** `/api/delivery/update-location/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "latitude": 19.0760,
    "longitude": 72.8777,
    "assignment_id": "uuid"
  }
  ```

**Error Handling:**
- Handle location permission errors
- Display navigation errors
- Show route calculation errors

---

### 15. Customer Navigation Screen

**Purpose/Functionality:**
- Provides navigation to customer delivery location
- Shows map with route to customer
- Displays estimated arrival time
- Updates location in real-time

**User Actions:**
- View map with customer location
- Start navigation to customer
- View route and distance
- Update location
- Mark arrived at customer

**API Endpoints:**

#### Get Order Detail (for navigation)
- **Method:** `GET`
- **Endpoint:** `/api/delivery/assignments/{assignment_id}/`
- **Authentication:** Required (Delivery Person)

#### Update Location
- **Method:** `POST`
- **Endpoint:** `/api/delivery/update-location/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "latitude": 19.2183,
    "longitude": 72.9781,
    "assignment_id": "uuid"
  }
  ```

**Error Handling:**
- Handle location permission errors
- Display navigation errors
- Show route calculation errors

---

## Earnings & History Screens

### 16. Order History Screen

**Purpose/Functionality:**
- Displays completed delivery history
- Shows past orders with details
- Filters by date range
- Shows earnings per delivery

**User Actions:**
- View order history
- Filter by date range
- View order details
- Check earnings per order
- Export history

**API Endpoints:**

#### Get Order History
- **Method:** `GET`
- **Endpoint:** `/api/delivery/orders/history/`
- **Authentication:** Required (Delivery Person)
- **Query Parameters:**
  - `start_date`: Start date
  - `end_date`: End date
  - `page`: Page number
  - `page_size`: Items per page
- **Response (200 OK):**
  ```json
  {
    "count": 100,
    "results": [
      {
        "id": "uuid",
        "order": {
          "id": "uuid",
          "order_number": "ORD-2024-001",
          "vendor": {
            "name": "Pizza Palace"
          },
          "delivery_address": {
            "address_line_1": "456 Customer St"
          },
          "total_amount": 623.00
        },
        "status": "completed",
        "earnings": 50.00,
        "delivered_at": "2024-01-15T12:05:00Z",
        "distance_km": 5.2
      }
    ]
  }
  ```

**Error Handling:**
- Handle empty history
- Display date range errors
- Show pagination errors

---

### 17. Earnings Screen

**Purpose/Functionality:**
- Displays earnings summary and history
- Shows pending and settled earnings
- Provides earnings breakdown by period
- Shows payment history

**User Actions:**
- View earnings summary
- Select time period (today, week, month)
- View earnings breakdown
- Check pending earnings
- View settled earnings
- View payment history

**API Endpoints:**

#### Get Earnings History
- **Method:** `GET`
- **Endpoint:** `/api/delivery/earnings/`
- **Authentication:** Required (Delivery Person)
- **Query Parameters:**
  - `period`: Time period (`today`, `week`, `month`, `custom`)
  - `start_date`: Start date (for custom period)
  - `end_date`: End date (for custom period)
  - `page`: Page number
- **Response (200 OK):**
  ```json
  {
    "period": "today",
    "total_earnings": 500.00,
    "pending_earnings": 500.00,
    "settled_earnings": 0.00,
    "deliveries_count": 5,
    "average_earnings_per_delivery": 100.00,
    "breakdown": [
      {
        "date": "2024-01-15",
        "earnings": 500.00,
        "deliveries": 5
      }
    ]
  }
  ```

**Error Handling:**
- Handle invalid date ranges
- Display empty earnings
- Show calculation errors

---

### 18. Performance Screen

**Purpose/Functionality:**
- Displays performance metrics
- Shows on-time delivery rate
- Displays average delivery time
- Shows customer ratings

**User Actions:**
- View performance metrics
- Check on-time delivery rate
- View average delivery time
- Check customer ratings
- View performance trends

**API Endpoints:**

#### Get Performance
- **Method:** `GET`
- **Endpoint:** `/api/delivery/performance/`
- **Authentication:** Required (Delivery Person)
- **Query Parameters:**
  - `date`: Specific date (optional)
- **Response (200 OK):**
  ```json
  {
    "date": "2024-01-15",
    "on_time_delivery_rate": 95.0,
    "average_delivery_time": 25,
    "total_deliveries": 5,
    "completed_deliveries": 5,
    "cancelled_deliveries": 0,
    "customer_rating": 4.8,
    "total_ratings": 50
  }
  ```

**Error Handling:**
- Handle missing performance data
- Display calculation errors

---

## Profile & Support Screens

### 19. Profile Screen

**Purpose/Functionality:**
- Displays delivery person profile information
- Allows editing profile details
- Manages vehicle information
- Updates contact information

**User Actions:**
- View profile information
- Edit profile (name, phone, email, photo)
- Update vehicle information
- Change password
- View delivery statistics

**API Endpoints:**

#### Get Delivery Person Profile
- **Method:** `GET`
- **Endpoint:** `/api/users/delivery-profile/`
- **Authentication:** Required (Delivery Person)
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "user": {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe",
      "email": "delivery@example.com",
      "phone_number": "+919876543210"
    },
    "rating": 4.8,
    "total_deliveries": 150,
    "vehicle_type": "Bike",
    "vehicle_number": "MH-01-AB-1234",
    "license_number": "DL1234567890",
    "is_available": true,
    "current_latitude": 19.0760,
    "current_longitude": 72.8777
  }
  ```

#### Update Profile
- **Method:** `PATCH`
- **Endpoint:** `/api/users/profile/update/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "first_name": "John",
    "last_name": "Doe",
    "email": "newemail@example.com"
  }
  ```

**Error Handling:**
- Validate profile data
- Handle duplicate email/phone
- Display update errors

---

### 20. Support Screen

**Purpose/Functionality:**
- Allows reporting issues
- Provides contact information
- Shows help and FAQ
- Access to customer support

**User Actions:**
- Report delivery issues
- Contact support
- View help articles
- Submit feedback

**API Endpoints:**

#### Report Issue
- **Method:** `POST`
- **Endpoint:** `/api/delivery/issues/`
- **Authentication:** Required (Delivery Person)
- **Request Body:**
  ```json
  {
    "issue_type": "order_issue",
    "title": "Customer not available",
    "description": "Customer was not available at delivery location",
    "order_id": "uuid",
    "priority": "medium"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": "uuid",
    "issue_type": "order_issue",
    "title": "Customer not available",
    "status": "open",
    "created_on": "2024-01-15T12:00:00Z"
  }
  ```

**Error Handling:**
- Validate issue data
- Handle issue submission errors
- Display confirmation messages

---

## Token Management

### Refresh Token
- **Method:** `POST`
- **Endpoint:** `/api/auth/token/refresh/`
- **Authentication:** Not required (uses refresh token)
- **Request Body:**
  ```json
  {
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  }
  ```

---

## Error Handling Summary

### Common Error Codes
- `400 Bad Request`: Invalid request data or validation errors
- `401 Unauthorized`: Missing or invalid authentication token
- `403 Forbidden`: User is not a delivery person or insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Permission Errors
- All delivery endpoints require `IsDeliveryPerson` permission
- User must have an associated delivery profile
- Delivery person must be online to receive new assignments

### Error Response Format
```json
{
  "error": "Error message",
  "detail": "Detailed error description",
  "code": "ERROR_CODE"
}
```

### Best Practices
1. Always include `Authorization: Bearer {access_token}` header
2. Handle token expiration and refresh automatically
3. Update location regularly (every 30 seconds when active)
4. Validate OTP before submission
5. Show user-friendly error messages
6. Handle offline scenarios gracefully
7. Implement retry logic for network errors
8. Request location permissions on app start
9. Keep GPS tracking active during active deliveries

---

## WebSocket Support

### Real-time Order Updates
- **WebSocket URL:** `ws://your-domain.com/ws/orders/`
- **Authentication:** JWT token in query parameter or header
- **Events:**
  - `new_assignment`: New order assignment received
  - `assignment_update`: Assignment status changed
  - `order_status_update`: Order status changed

### Connection Example
```javascript
const ws = new WebSocket('ws://your-domain.com/ws/orders/?token=ACCESS_TOKEN');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // Handle order updates
};
```

---

## Location Tracking Best Practices

1. **Update Frequency:**
   - Update location every 30 seconds when online
   - Update location every 5 seconds during active delivery
   - Update location when status changes (arrived, picked up, delivered)

2. **Battery Optimization:**
   - Use location services efficiently
   - Reduce update frequency when not actively delivering
   - Use background location updates only when necessary

3. **Accuracy:**
   - Request high accuracy location when navigating
   - Use standard accuracy for general tracking
   - Handle location permission denials gracefully

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- All monetary values are in INR (Indian Rupees)
- Location coordinates are in decimal degrees (WGS84)
- OTP verification is required for pickup and delivery
- Delivery person must be online to receive new assignments
- Earnings are calculated based on distance and order value
- Performance metrics are calculated daily
- Location updates should be sent regularly for accurate tracking

