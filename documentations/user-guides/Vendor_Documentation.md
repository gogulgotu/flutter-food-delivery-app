# Vendor (Hotel Owner) Role Documentation

## Overview

This document provides comprehensive documentation for all screens, functionalities, and API endpoints available to **Vendor/Hotel Owner** users in the Flutter application. Vendors can manage their restaurant operations, process orders, manage menu items, view analytics, handle payments, and control restaurant settings.

---

## Table of Contents

1. [Authentication Screens](#authentication-screens)
2. [Dashboard Screens](#dashboard-screens)
3. [Order Management Screens](#order-management-screens)
4. [Menu Management Screens](#menu-management-screens)
5. [Restaurant Management Screens](#restaurant-management-screens)
6. [Analytics & Reports Screens](#analytics--reports-screens)
7. [Payments & Settlements Screens](#payments--settlements-screens)
8. [Offers & Marketing Screens](#offers--marketing-screens)
9. [Ratings & Feedback Screens](#ratings--feedback-screens)

---

## Authentication Screens

### 1. Login Screen

**Purpose/Functionality:**
- Allows vendors to authenticate using mobile number and OTP or email/password
- Validates vendor account status
- Ensures user has vendor/hotel owner role

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
    "email": "vendor@example.com",
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
      "email": "vendor@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "user_role_name": "Hotel Owner"
    }
  }
  ```

**Error Handling:**
- Display error for invalid credentials
- Check if user has vendor role
- Validate vendor account status
- Handle network errors

---

### 2. OTP Verification Screen

**Purpose/Functionality:**
- Verifies OTP sent to vendor's mobile number
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
      "user_role_name": "Hotel Owner"
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

### 3. Dashboard Home Screen

**Purpose/Functionality:**
- Main dashboard showing key metrics and statistics
- Displays live orders, revenue, ratings, and alerts
- Provides quick overview of restaurant performance
- Shows restaurant status and controls

**User Actions:**
- View dashboard statistics
- Toggle restaurant status (online/offline/paused)
- View live orders count
- Check today's revenue and orders
- View delayed orders and complaints
- Access quick actions

**API Endpoints:**

#### Get Dashboard Home Stats
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/home/`
- **Authentication:** Required (Vendor Owner)
- **Response (200 OK):**
  ```json
  {
    "live_orders": 5,
    "today_revenue": 12500.00,
    "current_rating": 4.5,
    "today_orders": 25,
    "delayed_orders": 2,
    "complaints": 1,
    "avg_delivery_time": 35,
    "customer_satisfaction": 85,
    "restaurant_status": "online"
  }
  ```
- **Error Responses:**
  - `403 Forbidden`: User is not a vendor owner
  - `404 Not Found`: No vendor associated with account

**Error Handling:**
- Handle missing vendor association
- Display error if vendor account not set up
- Show loading state during data fetch

---

### 4. Sales Trend Screen

**Purpose/Functionality:**
- Displays sales trend data in chart format
- Shows revenue over different time periods (hourly, daily, weekly, monthly)
- Helps analyze sales patterns and trends

**User Actions:**
- Select time period (hourly, daily, weekly, monthly)
- View sales chart
- Analyze revenue trends
- Export sales data

**API Endpoints:**

#### Get Sales Trend
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/sales-trend/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `period`: Time period (`hourly`, `daily`, `weekly`, `monthly`)
- **Response (200 OK):**
  ```json
  [
    {
      "time": "2024-01-15",
      "sales": 5000.00
    },
    {
      "time": "2024-01-16",
      "sales": 7500.00
    }
  ]
  ```

**Error Handling:**
- Handle invalid period parameter
- Display empty state when no data
- Show error for date range issues

---

### 5. Notifications Screen

**Purpose/Functionality:**
- Displays important notifications and alerts
- Shows delayed orders, complaints, and system alerts
- Provides quick access to relevant actions

**User Actions:**
- View notifications list
- Filter notifications by type
- Mark notifications as read
- Navigate to related orders/items

**API Endpoints:**

#### Get Dashboard Notifications
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/notifications/`
- **Authentication:** Required (Vendor Owner)
- **Response (200 OK):**
  ```json
  [
    {
      "id": "delay_123",
      "type": "delay",
      "message": "Order ORD-2024-001 delayed by 15 minutes",
      "time": "15 min ago",
      "priority": "high"
    },
    {
      "id": "complaint_456",
      "type": "complaint",
      "message": "Customer complaint on Order ORD-2024-002",
      "time": "2 hours ago",
      "priority": "high"
    }
  ]
  ```

**Error Handling:**
- Handle empty notifications
- Display error messages
- Show loading state

---

## Order Management Screens

### 6. Orders List Screen

**Purpose/Functionality:**
- Displays all orders for the restaurant
- Allows filtering by status, date, and search
- Shows order summary statistics
- Provides quick order actions

**User Actions:**
- View orders list
- Filter by status (Pending, Confirmed, Preparing, Ready, Delivered, Cancelled)
- Filter by date (Today, Yesterday, Past 7 days, Custom range)
- Search orders by order number or customer name
- View order details
- Take order actions (Accept, Reject, Mark Ready, etc.)

**API Endpoints:**

#### List Orders
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/orders/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `filter`: Filter type (`all`, `live`, `completed`)
  - `status`: Order status filter
  - `date`: Date filter (`today`, `yesterday`, `past_7_days`, `custom`, `all`)
  - `start_date`: Start date (for custom range)
  - `end_date`: End date (for custom range)
  - `search`: Search query (order number or customer name)
  - `page`: Page number
  - `page_size`: Items per page
  - `include_cancelled`: Include cancelled orders (`true`/`false`)
- **Response (200 OK):**
  ```json
  {
    "count": 50,
    "next": "http://api.example.com/api/dashboard/orders/?page=2",
    "previous": null,
    "results": [
      {
        "id": "uuid",
        "order_number": "ORD-2024-001",
        "customer": {
          "id": "uuid",
          "first_name": "John",
          "last_name": "Doe",
          "phone": "+919876543210"
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
        "delivery_status": "pending",
        "order_placed_at": "2024-01-15T10:30:00Z",
        "estimated_delivery_time": "2024-01-15T12:30:00Z"
      }
    ],
    "status_summary": {
      "total": 50,
      "pending": 5,
      "confirmed": 10,
      "preparing": 8,
      "ready": 3,
      "out_for_delivery": 4,
      "delivered": 18,
      "cancelled": 2
    },
    "date_context": {
      "current_filter": "today",
      "start_date": "2024-01-15",
      "end_date": "2024-01-15"
    }
  }
  ```

**Error Handling:**
- Handle empty orders list
- Display error for invalid date ranges
- Show network errors
- Handle pagination errors

---

### 7. Order Detail Screen

**Purpose/Functionality:**
- Shows comprehensive order information
- Displays order items, customer details, delivery address
- Allows taking order actions (Accept, Reject, Mark Ready, Delay)
- Shows order timeline and status history

**User Actions:**
- View order details
- Accept or reject order
- Update preparation status
- Mark order as ready
- Delay order with reason
- View customer information
- Contact customer
- View delivery address

**API Endpoints:**

#### Get Order Details
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/orders/{order_id}/`
- **Authentication:** Required (Vendor Owner)
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "order_number": "ORD-2024-001",
    "customer": {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+919876543210",
      "email": "john@example.com"
    },
    "items": [
      {
        "id": "uuid",
        "product": {
          "id": "uuid",
          "name": "Margherita Pizza",
          "image": "https://example.com/pizza.jpg"
        },
        "quantity": 2,
        "unit_price": 299.00,
        "total_price": 598.00,
        "customizations": "Extra cheese, No onions"
      }
    ],
    "delivery_address": {
      "title": "Home",
      "address_line_1": "123 Main St",
      "city": "Mumbai",
      "postal_code": "400001",
      "latitude": 19.0760,
      "longitude": 72.8777
    },
    "subtotal": 598.00,
    "delivery_fee": 25.00,
    "tax": 74.75,
    "total_amount": 697.75,
    "order_status": "confirmed",
    "payment_status": "completed",
    "delivery_status": "pending",
    "order_placed_at": "2024-01-15T10:30:00Z",
    "estimated_delivery_time": "2024-01-15T12:30:00Z",
    "payment_method": "cod",
    "special_instructions": "Please ring the doorbell"
  }
  ```

#### Order Action (Accept, Reject, Ready, Delay)
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/orders/{order_id}/action/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "action": "accept",  // accept, reject, ready, delay
    "reason": "Order accepted and will be prepared",  // Optional for reject/delay
    "estimated_preparation_time": 30  // Optional for accept/delay (in minutes)
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Order accepted successfully",
    "order": {
      "id": "uuid",
      "order_status": "confirmed",
      "estimated_delivery_time": "2024-01-15T12:30:00Z"
    }
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Invalid action or order cannot be processed
  - `404 Not Found`: Order not found
  - `403 Forbidden`: Order does not belong to vendor

**Error Handling:**
- Validate order action eligibility
- Handle order not found errors
- Display action-specific error messages
- Show confirmation dialogs for critical actions

---

## Menu Management Screens

### 8. Menu List Screen

**Purpose/Functionality:**
- Displays all menu items (products) for the restaurant
- Allows filtering and searching menu items
- Shows product availability status
- Quick access to add, edit, or delete items

**User Actions:**
- View menu items list
- Filter by category or availability
- Search menu items
- Add new menu item
- Edit existing menu item
- Toggle item availability
- Delete menu item
- Reorder menu items

**API Endpoints:**

#### List Menu Items
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/menu/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `category`: Filter by category
  - `search`: Search query
  - `is_available`: Filter by availability (`true`/`false`)
  - `page`: Page number
  - `page_size`: Items per page
- **Response (200 OK):**
  ```json
  {
    "count": 50,
    "results": [
      {
        "id": "uuid",
        "name": "Margherita Pizza",
        "description": "Classic margherita pizza",
        "price": 299.00,
        "discounted_price": 249.00,
        "category": {
          "id": "uuid",
          "name": "Pizza"
        },
        "is_available": true,
        "image": "https://example.com/pizza.jpg",
        "preparation_time": 20,
        "stock_quantity": 10
      }
    ]
  }
  ```

**Error Handling:**
- Handle empty menu list
- Display search errors
- Show network errors

---

### 9. Menu Item Detail Screen

**Purpose/Functionality:**
- Shows detailed information about a menu item
- Allows editing all product details
- Manages product images and variants
- Controls availability and pricing

**User Actions:**
- View product details
- Edit product information
- Upload/change product images
- Manage product variants
- Update pricing
- Toggle availability
- Delete product

**API Endpoints:**

#### Get Menu Item Details
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/menu/{product_id}/`
- **Authentication:** Required (Vendor Owner)
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "name": "Margherita Pizza",
    "description": "Classic margherita pizza with fresh mozzarella",
    "price": 299.00,
    "discounted_price": 249.00,
    "category": {
      "id": "uuid",
      "name": "Pizza"
    },
    "is_available": true,
    "images": [
      "https://example.com/pizza1.jpg",
      "https://example.com/pizza2.jpg"
    ],
    "variants": [
      {
        "id": "uuid",
        "name": "Size",
        "options": [
          {"id": "uuid", "name": "Small", "price": 0},
          {"id": "uuid", "name": "Large", "price": 100}
        ]
      }
    ],
    "preparation_time": 20,
    "stock_quantity": 10,
    "nutritional_info": {
      "calories": 250,
      "protein": "12g",
      "carbs": "30g"
    }
  }
  ```

#### Update Menu Item
- **Method:** `PATCH`
- **Endpoint:** `/api/dashboard/menu/{product_id}/update/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:** `multipart/form-data` or `application/json`
  ```json
  {
    "name": "Margherita Pizza",
    "description": "Updated description",
    "price": 299.00,
    "discounted_price": 249.00,
    "category": "category-uuid",
    "is_available": true,
    "preparation_time": 20,
    "stock_quantity": 10
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "name": "Margherita Pizza",
    "price": 299.00,
    "is_available": true
  }
  ```

#### Delete Menu Item
- **Method:** `DELETE`
- **Endpoint:** `/api/dashboard/menu/{product_id}/delete/`
- **Authentication:** Required (Vendor Owner)
- **Response (204 No Content)**
- **Error Responses:**
  - `400 Bad Request`: Cannot delete item with active orders
  - `404 Not Found`: Product not found

**Error Handling:**
- Validate product data before update
- Handle image upload errors
- Prevent deletion of items with active orders
- Display validation errors

---

### 10. Create Menu Item Screen

**Purpose/Functionality:**
- Allows creating new menu items
- Collects product information, images, and variants
- Sets pricing and availability

**User Actions:**
- Fill product form (name, description, price, category)
- Upload product images
- Add product variants
- Set availability
- Save product

**API Endpoints:**

#### Create Menu Item
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/menu/create/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:** `multipart/form-data`
  ```
  name: Margherita Pizza
  description: Classic margherita pizza
  price: 299.00
  discounted_price: 249.00
  category: category-uuid
  is_available: true
  preparation_time: 20
  stock_quantity: 10
  images: [file1, file2]
  ```
- **Response (201 Created):**
  ```json
  {
    "id": "uuid",
    "name": "Margherita Pizza",
    "price": 299.00,
    "is_available": true
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Validation errors
  - `413 Payload Too Large`: Image file too large

**Error Handling:**
- Validate all required fields
- Check image file size and format
- Display field-specific errors
- Handle duplicate product names

---

### 11. Toggle Menu Item Availability

**Purpose/Functionality:**
- Quickly toggle product availability on/off
- Useful for temporarily disabling items

**User Actions:**
- Toggle availability switch
- Confirm action

**API Endpoints:**

#### Toggle Availability
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/menu/{product_id}/toggle-availability/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "is_available": false
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "is_available": false,
    "message": "Product availability updated"
  }
  ```

**Error Handling:**
- Handle product not found
- Display update errors

---

## Restaurant Management Screens

### 12. Restaurant Profile Screen

**Purpose/Functionality:**
- Displays restaurant information and settings
- Allows editing restaurant details
- Manages restaurant status and operating hours

**User Actions:**
- View restaurant information
- Edit restaurant details
- Update restaurant images
- Change operating hours
- Toggle restaurant status

**API Endpoints:**

#### Get Restaurant Details
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/vendor/`
- **Authentication:** Required (Vendor Owner)
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "name": "Pizza Palace",
    "description": "Best pizza in town",
    "address": "123 Food Street",
    "phone": "+919876543210",
    "email": "info@pizzapalace.com",
    "rating": 4.5,
    "is_active": true,
    "vendor_status": {
      "status_code": "ACTIVE",
      "name": "Active"
    },
    "images": [
      "https://example.com/restaurant1.jpg"
    ],
    "operating_hours": {
      "monday": {"open": "09:00", "close": "22:00", "is_open": true},
      "tuesday": {"open": "09:00", "close": "22:00", "is_open": true}
    },
    "cuisine_types": ["Italian", "Fast Food"],
    "delivery_fee": 25.00,
    "minimum_order": 100.00
  }
  ```

#### Update Restaurant Details
- **Method:** `PATCH`
- **Endpoint:** `/api/dashboard/vendor/update/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:** `multipart/form-data` or `application/json`
  ```json
  {
    "name": "Pizza Palace",
    "description": "Updated description",
    "address": "123 Food Street",
    "phone": "+919876543210",
    "email": "info@pizzapalace.com",
    "delivery_fee": 25.00,
    "minimum_order": 100.00
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "name": "Pizza Palace",
    "description": "Updated description"
  }
  ```

**Error Handling:**
- Validate restaurant data
- Handle image upload errors
- Display validation errors

---

### 13. Restaurant Status Toggle

**Purpose/Functionality:**
- Allows toggling restaurant status (online/offline/paused)
- Controls whether restaurant accepts new orders

**User Actions:**
- Toggle restaurant status
- Select status (online, offline, paused)
- Confirm status change

**API Endpoints:**

#### Toggle Restaurant Status
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/vendor/toggle-status/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "status": "paused"  // online, offline, paused
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "paused",
    "message": "Restaurant status updated successfully",
    "vendor": {
      "id": "uuid",
      "is_active": false,
      "vendor_status": {
        "status_code": "SUSPENDED",
        "name": "Paused"
      }
    }
  }
  ```

**Error Handling:**
- Validate status value
- Handle status change errors
- Show confirmation for status changes

---

### 14. Operating Hours Management Screen

**Purpose/Functionality:**
- Manages restaurant operating hours for each day
- Allows setting different hours for different days
- Bulk update and copy hours functionality

**User Actions:**
- View operating hours for each day
- Edit hours for specific days
- Bulk update hours
- Copy hours from one day to others
- Set days as closed

**API Endpoints:**

#### List Operating Hours
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/operating-hours/`
- **Authentication:** Required (Vendor Owner)
- **Response (200 OK):**
  ```json
  [
    {
      "id": 1,
      "day_of_week": "monday",
      "open_time": "09:00",
      "close_time": "22:00",
      "is_open": true
    },
    {
      "id": 2,
      "day_of_week": "tuesday",
      "open_time": "09:00",
      "close_time": "22:00",
      "is_open": true
    }
  ]
  ```

#### Update Operating Hours
- **Method:** `PATCH`
- **Endpoint:** `/api/dashboard/operating-hours/{hours_id}/update/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "open_time": "10:00",
    "close_time": "23:00",
    "is_open": true
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": 1,
    "day_of_week": "monday",
    "open_time": "10:00",
    "close_time": "23:00",
    "is_open": true
  }
  ```

#### Bulk Update Operating Hours
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/operating-hours/bulk-update/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "days": ["monday", "tuesday", "wednesday"],
    "open_time": "09:00",
    "close_time": "22:00",
    "is_open": true
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Operating hours updated successfully",
    "updated_count": 3
  }
  ```

#### Copy Operating Hours
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/operating-hours/copy/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "source_day": "monday",
    "target_days": ["tuesday", "wednesday", "thursday"]
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Operating hours copied successfully",
    "copied_count": 3
  }
  ```

**Error Handling:**
- Validate time formats
- Check open_time < close_time
- Handle invalid day names
- Display update errors

---

## Analytics & Reports Screens

### 15. Analytics Metrics Screen

**Purpose/Functionality:**
- Displays key performance metrics
- Shows comparisons with previous periods
- Provides insights into restaurant performance

**User Actions:**
- View analytics metrics
- Select time period
- Compare with previous period
- Export analytics data

**API Endpoints:**

#### Get Analytics Metrics
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/analytics/metrics/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `period`: Time period (`today`, `week`, `month`)
  - `compare_with`: Compare with (`previous_period`, `same_period_last_year`)
- **Response (200 OK):**
  ```json
  {
    "period": "today",
    "metrics": {
      "total_orders": 25,
      "total_revenue": 12500.00,
      "average_order_value": 500.00,
      "total_customers": 20,
      "repeat_customers": 8,
      "cancellation_rate": 5.0,
      "average_rating": 4.5
    },
    "comparison": {
      "total_orders_change": 10.5,
      "total_revenue_change": 15.2,
      "average_order_value_change": 4.3
    }
  }
  ```

**Error Handling:**
- Handle invalid period parameters
- Display empty state when no data
- Show comparison errors

---

### 16. Top Dishes Screen

**Purpose/Functionality:**
- Shows best-selling menu items
- Displays sales statistics for each product
- Helps identify popular items

**User Actions:**
- View top dishes list
- Filter by time period
- View sales statistics
- Sort by revenue or quantity

**API Endpoints:**

#### Get Top Dishes
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/analytics/top-dishes/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `period`: Time period (`today`, `week`, `month`)
  - `limit`: Number of items to return
- **Response (200 OK):**
  ```json
  {
    "period": "today",
    "dishes": [
      {
        "product": {
          "id": "uuid",
          "name": "Margherita Pizza",
          "image": "https://example.com/pizza.jpg"
        },
        "quantity_sold": 50,
        "revenue": 12450.00,
        "percentage_of_total": 25.5
      }
    ]
  }
  ```

**Error Handling:**
- Handle empty results
- Display period errors

---

## Payments & Settlements Screens

### 17. Earnings Screen

**Purpose/Functionality:**
- Displays earnings summary for different time periods
- Shows pending and settled earnings
- Provides earnings breakdown

**User Actions:**
- View earnings summary
- Select time period (today, week, month)
- View pending earnings
- Check settled earnings
- View earnings breakdown

**API Endpoints:**

#### Get Earnings Summary
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/earnings/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `period`: Time period (`today`, `week`, `month`, `custom`)
  - `start_date`: Start date (for custom period)
  - `end_date`: End date (for custom period)
- **Response (200 OK):**
  ```json
  {
    "period": "today",
    "total_earnings": 12500.00,
    "pending_earnings": 2500.00,
    "settled_earnings": 10000.00,
    "breakdown": {
      "order_revenue": 12000.00,
      "delivery_fee": 500.00,
      "commission": -1500.00,
      "tax": 1500.00
    }
  }
  ```

**Error Handling:**
- Handle invalid date ranges
- Display empty earnings
- Show calculation errors

---

### 18. Transactions Screen

**Purpose/Functionality:**
- Lists all payment transactions
- Shows transaction details and status
- Filters transactions by status and date

**User Actions:**
- View transactions list
- Filter by status (pending, settled, failed)
- Filter by date range
- View transaction details
- Export transactions

**API Endpoints:**

#### List Transactions
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/transactions/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `status`: Filter by status (`pending`, `settled`, `failed`)
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
          "order_number": "ORD-2024-001"
        },
        "amount": 623.00,
        "commission": 62.30,
        "net_amount": 560.70,
        "status": "settled",
        "settlement_date": "2024-01-16T10:00:00Z",
        "created_on": "2024-01-15T10:30:00Z"
      }
    ]
  }
  ```

**Error Handling:**
- Handle empty transactions
- Display filter errors
- Show pagination errors

---

## Offers & Marketing Screens

### 19. Promotions List Screen

**Purpose/Functionality:**
- Displays all active and past promotions
- Allows creating and managing promotions
- Shows promotion performance

**User Actions:**
- View promotions list
- Create new promotion
- Edit existing promotion
- Activate/deactivate promotions
- View promotion performance

**API Endpoints:**

#### List Promotions
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/promotions/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `status`: Filter by status (`active`, `inactive`, `expired`)
  - `page`: Page number
- **Response (200 OK):**
  ```json
  {
    "count": 10,
    "results": [
      {
        "id": "uuid",
        "title": "20% Off on Pizzas",
        "description": "Get 20% discount on all pizzas",
        "discount_type": "percentage",
        "discount_value": 20.00,
        "start_date": "2024-01-15T00:00:00Z",
        "end_date": "2024-01-31T23:59:59Z",
        "is_active": true,
        "applicable_products": ["product-uuid-1", "product-uuid-2"]
      }
    ]
  }
  ```

#### Create Promotion
- **Method:** `POST`
- **Endpoint:** `/api/dashboard/promotions/create/`
- **Authentication:** Required (Vendor Owner)
- **Request Body:**
  ```json
  {
    "title": "20% Off on Pizzas",
    "description": "Get 20% discount on all pizzas",
    "discount_type": "percentage",
    "discount_value": 20.00,
    "start_date": "2024-01-15T00:00:00Z",
    "end_date": "2024-01-31T23:59:59Z",
    "minimum_order_amount": 500.00,
    "applicable_products": ["product-uuid-1"]
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": "uuid",
    "title": "20% Off on Pizzas",
    "is_active": true
  }
  ```

**Error Handling:**
- Validate promotion dates
- Check discount values
- Handle product selection errors
- Display validation errors

---

## Ratings & Feedback Screens

### 20. Ratings Summary Screen

**Purpose/Functionality:**
- Displays overall rating and rating breakdown
- Shows rating trends over time
- Provides insights into customer satisfaction

**User Actions:**
- View overall rating
- Check rating breakdown (5-star, 4-star, etc.)
- View rating trends
- Analyze customer satisfaction

**API Endpoints:**

#### Get Ratings Summary
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/ratings/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `period`: Time period (`week`, `month`, `all`)
- **Response (200 OK):**
  ```json
  {
    "overall_rating": 4.5,
    "total_ratings": 150,
    "rating_breakdown": {
      "5": 80,
      "4": 50,
      "3": 15,
      "2": 3,
      "1": 2
    },
    "average_by_category": {
      "food_quality": 4.6,
      "delivery": 4.3,
      "packaging": 4.5
    }
  }
  ```

**Error Handling:**
- Handle empty ratings
- Display period errors

---

### 21. Reviews List Screen

**Purpose/Functionality:**
- Lists all customer reviews
- Allows responding to reviews
- Filters reviews by rating

**User Actions:**
- View reviews list
- Filter by rating
- Respond to reviews
- View review details

**API Endpoints:**

#### List Reviews
- **Method:** `GET`
- **Endpoint:** `/api/dashboard/reviews/`
- **Authentication:** Required (Vendor Owner)
- **Query Parameters:**
  - `rating`: Filter by rating (1-5)
  - `page`: Page number
  - `page_size`: Items per page
- **Response (200 OK):**
  ```json
  {
    "count": 50,
    "results": [
      {
        "id": "uuid",
        "order": {
          "id": "uuid",
          "order_number": "ORD-2024-001"
        },
        "customer": {
          "first_name": "John",
          "last_name": "Doe"
        },
        "overall_rating": 5,
        "food_quality_rating": 5,
        "delivery_rating": 4,
        "packaging_rating": 5,
        "comment": "Great food and fast delivery!",
        "created_on": "2024-01-15T13:00:00Z",
        "response": {
          "message": "Thank you for your feedback!",
          "created_on": "2024-01-15T14:00:00Z"
        }
      }
    ]
  }
  ```

**Error Handling:**
- Handle empty reviews
- Display filter errors
- Show response submission errors

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
- `403 Forbidden`: User is not a vendor owner or insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Permission Errors
- All dashboard endpoints require `IsVendorOwner` permission
- User must have an associated vendor account
- Vendor account must be active

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
3. Validate vendor ownership before API calls
4. Show user-friendly error messages
5. Handle offline scenarios gracefully
6. Implement retry logic for network errors
7. Log errors for debugging

---

## WebSocket Support

### Real-time Order Updates
- **WebSocket URL:** `ws://your-domain.com/ws/orders/`
- **Authentication:** JWT token in query parameter or header
- **Events:**
  - `new_order`: New order received
  - `order_status_update`: Order status changed
  - `order_cancelled`: Order cancelled

### Connection Example
```javascript
const ws = new WebSocket('ws://your-domain.com/ws/orders/?token=ACCESS_TOKEN');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // Handle order updates
};
```

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- All monetary values are in INR (Indian Rupees)
- Image uploads require `multipart/form-data` content type
- Pagination is supported on list endpoints
- Rate limiting may apply to certain endpoints
- Vendor must be active to accept new orders
- Operating hours affect order acceptance

