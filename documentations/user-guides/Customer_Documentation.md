# Customer Role Documentation

## Overview

This document provides comprehensive documentation for all screens, functionalities, and API endpoints available to **Customer** users in the Flutter application. Customers can browse restaurants, place orders, track deliveries, manage their profile, and interact with the food delivery platform.

---

## Table of Contents

1. [Authentication Screens](#authentication-screens)
2. [Home & Discovery Screens](#home--discovery-screens)
3. [Restaurant & Product Screens](#restaurant--product-screens)
4. [Cart & Checkout Screens](#cart--checkout-screens)
5. [Order Management Screens](#order-management-screens)
6. [Profile & Account Screens](#profile--account-screens)
7. [Payment Screens](#payment-screens)

---

## Authentication Screens

### 1. Login Screen

**Purpose/Functionality:**
- Allows customers to authenticate using mobile number and OTP or email/password
- First step in the authentication flow
- Supports OTP-based authentication (primary) and traditional login

**User Actions:**
- Enter mobile number or email
- Select authentication method (OTP or Password)
- Tap "Send OTP" or "Login" button
- Navigate to OTP verification screen (if OTP selected)
- Navigate to registration screen (if new user)

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
- **Error Responses:**
  - `400 Bad Request`: Invalid mobile number format
  - `429 Too Many Requests`: Too many OTP requests

#### Login with Credentials
- **Method:** `POST`
- **Endpoint:** `/api/auth/login-user/`
- **Authentication:** Not required
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
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
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "user_role_name": "Customer"
    }
  }
  ```
- **Error Responses:**
  - `401 Unauthorized`: Invalid credentials
  - `400 Bad Request`: Missing required fields

**Error Handling:**
- Display error messages for invalid credentials
- Handle network errors gracefully
- Show loading state during API calls
- Validate mobile number format before sending OTP

---

### 2. OTP Verification Screen

**Purpose/Functionality:**
- Verifies the OTP sent to customer's mobile number
- Completes the authentication process
- Returns JWT tokens for subsequent API calls

**User Actions:**
- Enter 6-digit OTP received via SMS
- Tap "Verify OTP" button
- Request resend OTP if not received
- Navigate back to login screen

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
    "user_type": "existing",  // or "new"
    "user": {
      "id": "uuid",
      "phone_number": "+919876543210",
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
- **Error Responses:**
  - `400 Bad Request`: Invalid or expired OTP
  - `404 Not Found`: OTP not found

**Error Handling:**
- Display error for invalid/expired OTP
- Show countdown timer for OTP expiry
- Enable resend OTP after 60 seconds
- Handle OTP verification failures

---

### 3. Registration Screen

**Purpose/Functionality:**
- Allows new customers to create an account
- Collects user information (name, email, phone, password)
- Initiates OTP verification process

**User Actions:**
- Fill registration form (first name, last name, email, phone, password)
- Accept terms and conditions
- Tap "Register" button
- Navigate to OTP verification screen

**API Endpoints:**

#### Register User
- **Method:** `POST`
- **Endpoint:** `/api/auth/register/`
- **Authentication:** Not required
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+919876543210"
  }
  ```
- **Response (201 Created):**
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
- **Error Responses:**
  - `400 Bad Request`: Validation errors (duplicate email, weak password, etc.)
  - `409 Conflict`: User already exists

**Error Handling:**
- Validate form fields before submission
- Display field-specific error messages
- Check password strength requirements
- Handle duplicate email/phone errors

---

## Home & Discovery Screens

### 4. Home Screen

**Purpose/Functionality:**
- Main landing screen after login
- Displays featured restaurants, categories, and promotions
- Provides quick access to search and popular items
- Shows personalized recommendations

**User Actions:**
- Browse featured restaurants
- View categories
- Search for restaurants/products
- Tap on restaurant cards to view details
- Scroll through promotions and offers
- Access location selector

**API Endpoints:**

#### Get Home Data
- **Method:** `GET`
- **Endpoint:** `/api/home-data/`
- **Authentication:** Not required (optional for personalized content)
- **Query Parameters:**
  - `latitude` (optional): User's latitude
  - `longitude` (optional): User's longitude
- **Response (200 OK):**
  ```json
  {
    "featured_vendors": [...],
    "categories": [...],
    "promotions": [...],
    "popular_products": [...]
  }
  ```

**Error Handling:**
- Handle network errors gracefully
- Show cached data if available
- Display empty states when no data

---

### 5. Search Screen

**Purpose/Functionality:**
- Allows customers to search for restaurants and products
- Provides filters for refining search results
- Shows search history and suggestions

**User Actions:**
- Enter search query
- Apply filters (category, price range, rating, etc.)
- Tap on search results
- Clear search
- View search history

**API Endpoints:**

#### Search
- **Method:** `GET`
- **Endpoint:** `/api/search/`
- **Authentication:** Not required
- **Query Parameters:**
  - `q`: Search query
  - `type`: Type of search (vendor, product, both)
  - `category`: Filter by category
  - `min_price`: Minimum price
  - `max_price`: Maximum price
  - `rating`: Minimum rating
- **Response (200 OK):**
  ```json
  {
    "vendors": [...],
    "products": [...],
    "count": 25
  }
  ```

**Error Handling:**
- Show "No results found" message
- Handle empty search queries
- Display loading state during search

---

## Restaurant & Product Screens

### 6. Restaurant List Screen

**Purpose/Functionality:**
- Displays list of available restaurants/vendors
- Shows restaurant details (name, rating, delivery time, cuisine)
- Allows filtering and sorting

**User Actions:**
- Browse restaurant list
- Apply filters (category, rating, delivery time, price range)
- Sort restaurants (rating, delivery time, price)
- Tap restaurant card to view details
- Pull to refresh

**API Endpoints:**

#### List Vendors
- **Method:** `GET`
- **Endpoint:** `/api/vendors/`
- **Authentication:** Not required
- **Query Parameters:**
  - `category`: Filter by category slug
  - `search`: Search by name
  - `page`: Page number
  - `page_size`: Items per page
  - `min_rating`: Minimum rating
  - `delivery_time`: Maximum delivery time
- **Response (200 OK):**
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
        "image": "https://example.com/image.jpg",
        "cuisine_types": ["Italian", "Fast Food"]
      }
    ]
  }
  ```

#### Get Vendor Categories
- **Method:** `GET`
- **Endpoint:** `/api/vendor-categories/`
- **Authentication:** Not required
- **Response (200 OK):**
  ```json
  [
    {
      "id": "uuid",
      "name": "Italian",
      "slug": "italian",
      "icon": "https://example.com/icon.jpg"
    }
  ]
  ```

**Error Handling:**
- Display empty state when no restaurants found
- Handle pagination errors
- Show network error messages

---

### 7. Restaurant Detail Screen

**Purpose/Functionality:**
- Shows detailed information about a restaurant
- Displays menu items, reviews, ratings
- Allows adding items to cart
- Shows operating hours and location

**User Actions:**
- View restaurant information
- Browse menu items
- Filter menu by category
- Add items to cart
- View reviews and ratings
- Check operating hours
- Navigate to restaurant location

**API Endpoints:**

#### Get Vendor Details
- **Method:** `GET`
- **Endpoint:** `/api/vendors/{slug}/`
- **Authentication:** Not required
- **Response (200 OK):**
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
    },
    "images": ["https://example.com/image1.jpg"]
  }
  ```

#### Get Vendor Reviews
- **Method:** `GET`
- **Endpoint:** `/api/vendors/{slug}/reviews/`
- **Authentication:** Not required
- **Query Parameters:**
  - `page`: Page number
  - `page_size`: Items per page
- **Response (200 OK):**
  ```json
  {
    "count": 50,
    "results": [
      {
        "id": "uuid",
        "user": {
          "first_name": "John",
          "last_name": "Doe"
        },
        "rating": 5,
        "comment": "Great food!",
        "created_on": "2024-01-15T10:30:00Z"
      }
    ]
  }
  ```

**Error Handling:**
- Handle restaurant not found (404)
- Show error if restaurant is closed
- Display message if minimum order not met

---

### 8. Product List Screen

**Purpose/Functionality:**
- Displays products from a specific restaurant or all products
- Shows product details (name, price, image, description)
- Allows filtering and searching products

**User Actions:**
- Browse products
- Filter by category, price, availability
- Search products
- Tap product to view details
- Add products to cart

**API Endpoints:**

#### List Products
- **Method:** `GET`
- **Endpoint:** `/api/products/`
- **Authentication:** Not required
- **Query Parameters:**
  - `vendor`: Filter by vendor ID or slug
  - `category`: Filter by category
  - `search`: Search products
  - `min_price`: Minimum price
  - `max_price`: Maximum price
  - `is_available`: Filter by availability
  - `page`: Page number
- **Response (200 OK):**
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
        "vendor": {
          "id": "uuid",
          "name": "Pizza Palace"
        },
        "category": "Pizza",
        "is_available": true,
        "image": "https://example.com/pizza.jpg"
      }
    ]
  }
  ```

#### Get Product Categories
- **Method:** `GET`
- **Endpoint:** `/api/product-categories/`
- **Authentication:** Not required
- **Response (200 OK):**
  ```json
  [
    {
      "id": "uuid",
      "name": "Pizza",
      "slug": "pizza"
    }
  ]
  ```

**Error Handling:**
- Show empty state when no products
- Handle filter errors
- Display unavailable products with disabled state

---

### 9. Product Detail Screen

**Purpose/Functionality:**
- Shows detailed product information
- Displays product images, variants, customization options
- Allows adding product to cart with customizations
- Shows reviews and ratings

**User Actions:**
- View product details and images
- Select variants (size, toppings, etc.)
- Customize product (add/remove ingredients)
- Set quantity
- Add to cart
- View reviews
- Share product

**API Endpoints:**

#### Get Product Details
- **Method:** `GET`
- **Endpoint:** `/api/products/{slug}/`
- **Authentication:** Not required
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "name": "Margherita Pizza",
    "slug": "margherita-pizza",
    "description": "Classic margherita pizza with fresh mozzarella",
    "price": 299.00,
    "discounted_price": 249.00,
    "vendor": {
      "id": "uuid",
      "name": "Pizza Palace"
    },
    "category": "Pizza",
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
    "nutritional_info": {
      "calories": 250,
      "protein": "12g",
      "carbs": "30g"
    }
  }
  ```

#### Get Product Reviews
- **Method:** `GET`
- **Endpoint:** `/api/products/{slug}/reviews/`
- **Authentication:** Not required
- **Response (200 OK):**
  ```json
  {
    "count": 25,
    "results": [
      {
        "id": "uuid",
        "user": {
          "first_name": "John",
          "last_name": "Doe"
        },
        "rating": 5,
        "comment": "Delicious!",
        "created_on": "2024-01-15T10:30:00Z"
      }
    ]
  }
  ```

**Error Handling:**
- Handle product not found
- Show error if product unavailable
- Validate variant selections
- Handle out of stock scenarios

---

## Cart & Checkout Screens

### 10. Cart Screen

**Purpose/Functionality:**
- Displays items in shopping cart
- Allows updating quantities and removing items
- Shows cart total, delivery fee, and taxes
- Validates minimum order amount

**User Actions:**
- View cart items
- Increase/decrease item quantity
- Remove items from cart
- Apply promo codes
- Proceed to checkout
- Continue shopping

**API Endpoints:**

#### Get Cart
- **Method:** `GET`
- **Endpoint:** `/api/cart/`
- **Authentication:** Required
- **Query Parameters:**
  - `vendor`: Vendor ID (required)
- **Response (200 OK):**
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
          "price": 299.00,
          "image": "https://example.com/pizza.jpg"
        },
        "quantity": 2,
        "unit_price": 299.00,
        "total_price": 598.00,
        "variant": {
          "name": "Large",
          "price": 100
        }
      }
    ],
    "subtotal": 598.00,
    "delivery_fee": 25.00,
    "tax": 74.75,
    "total": 697.75
  }
  ```

#### Update Cart Item
- **Method:** `PATCH`
- **Endpoint:** `/api/cart/items/{id}/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "quantity": 3
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": 1,
    "quantity": 3,
    "total_price": 897.00
  }
  ```

#### Remove Cart Item
- **Method:** `DELETE`
- **Endpoint:** `/api/cart/items/{id}/delete/`
- **Authentication:** Required
- **Response (204 No Content)**

**Error Handling:**
- Validate minimum order amount
- Handle item unavailability
- Show error if vendor is closed
- Display cart empty state

---

### 11. Checkout Screen

**Purpose/Functionality:**
- Final step before placing order
- Allows selecting delivery address
- Choose payment method
- Review order summary
- Place order

**User Actions:**
- Select or add delivery address
- Choose payment method (COD, Online, Wallet)
- Apply promo codes
- Review order details
- Place order
- Navigate to payment screen (if online payment)

**API Endpoints:**

#### List Addresses
- **Method:** `GET`
- **Endpoint:** `/api/addresses/`
- **Authentication:** Required
- **Response (200 OK):**
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

#### Create Address
- **Method:** `POST`
- **Endpoint:** `/api/addresses/`
- **Authentication:** Required
- **Request Body:**
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
- **Response (201 Created):**
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

#### Get Payment Methods
- **Method:** `GET`
- **Endpoint:** `/api/payment-methods/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  [
    {
      "id": "uuid",
      "method_type": "cod",
      "name": "Cash on Delivery",
      "is_active": true
    },
    {
      "id": "uuid",
      "method_type": "razorpay",
      "name": "Online Payment",
      "is_active": true
    }
  ]
  ```

#### Create Order
- **Method:** `POST`
- **Endpoint:** `/api/orders/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "vendor": "vendor-uuid",
    "delivery_address": 1,
    "items": [
      {
        "product": "product-uuid",
        "quantity": 2,
        "price": 299.00,
        "variant": "variant-uuid"
      }
    ],
    "subtotal": 598.00,
    "delivery_fee": 25.00,
    "total_amount": 623.00,
    "payment_method": "cod",
    "scheduled_delivery_time": "2024-01-15T12:00:00Z"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": "uuid",
    "order_number": "ORD-2024-001",
    "status": "pending",
    "total_amount": 623.00,
    "payment_status": "pending",
    "estimated_delivery_time": "2024-01-15T12:30:00Z"
  }
  ```

**Error Handling:**
- Validate delivery address
- Check minimum order amount
- Handle payment method errors
- Show order placement errors
- Validate cart items availability

---

## Order Management Screens

### 12. Orders List Screen

**Purpose/Functionality:**
- Displays customer's order history
- Shows order status, date, and total amount
- Allows filtering by order status
- Quick access to order details and tracking

**User Actions:**
- View order history
- Filter orders by status (pending, confirmed, preparing, delivered, cancelled)
- Tap order to view details
- Track active orders
- Reorder previous orders

**API Endpoints:**

#### List Orders
- **Method:** `GET`
- **Endpoint:** `/api/orders/`
- **Authentication:** Required
- **Query Parameters:**
  - `status`: Filter by order status
  - `page`: Page number
  - `page_size`: Items per page
- **Response (200 OK):**
  ```json
  {
    "count": 20,
    "next": "http://api.example.com/api/orders/?page=2",
    "previous": null,
    "results": [
      {
        "id": "uuid",
        "order_number": "ORD-2024-001",
        "vendor": {
          "id": "uuid",
          "name": "Pizza Palace",
          "image": "https://example.com/image.jpg"
        },
        "total_amount": 623.00,
        "order_status": "confirmed",
        "payment_status": "completed",
        "delivery_status": "out_for_delivery",
        "order_placed_at": "2024-01-15T10:30:00Z",
        "estimated_delivery_time": "2024-01-15T12:30:00Z"
      }
    ]
  }
  ```

**Error Handling:**
- Show empty state when no orders
- Handle pagination errors
- Display network errors

---

### 13. Order Detail Screen

**Purpose/Functionality:**
- Shows comprehensive order information
- Displays order items, status, timeline
- Allows order cancellation (if applicable)
- Access to order tracking and rating

**User Actions:**
- View order details
- Track order status
- Cancel order (if allowed)
- Rate and review order
- Contact support
- Reorder items

**API Endpoints:**

#### Get Order Details
- **Method:** `GET`
- **Endpoint:** `/api/orders/{id}/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "order_number": "ORD-2024-001",
    "vendor": {
      "id": "uuid",
      "name": "Pizza Palace",
      "phone": "+919876543210",
      "address": "123 Food Street"
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
        "total_price": 598.00
      }
    ],
    "delivery_address": {
      "title": "Home",
      "address_line_1": "123 Main St",
      "city": "Mumbai",
      "postal_code": "400001"
    },
    "subtotal": 598.00,
    "delivery_fee": 25.00,
    "tax": 74.75,
    "total_amount": 697.75,
    "order_status": "confirmed",
    "payment_status": "completed",
    "delivery_status": "out_for_delivery",
    "order_placed_at": "2024-01-15T10:30:00Z",
    "estimated_delivery_time": "2024-01-15T12:30:00Z",
    "payment_method": "cod"
  }
  ```

#### Get Order Status
- **Method:** `GET`
- **Endpoint:** `/api/orders/{id}/status/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "order_status": "confirmed",
    "delivery_status": "out_for_delivery",
    "payment_status": "completed",
    "updated_at": "2024-01-15T11:00:00Z"
  }
  ```

#### Get Order History
- **Method:** `GET`
- **Endpoint:** `/api/orders/{id}/history/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "order_id": "uuid",
    "status_history": [
      {
        "status": "pending",
        "timestamp": "2024-01-15T10:30:00Z",
        "description": "Order placed"
      },
      {
        "status": "confirmed",
        "timestamp": "2024-01-15T10:35:00Z",
        "description": "Restaurant confirmed order"
      }
    ]
  }
  ```

#### Cancel Order
- **Method:** `POST`
- **Endpoint:** `/api/orders/{id}/cancel/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "cancellation_reason": "Changed my mind"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Order cancelled successfully",
    "order_id": "uuid",
    "refund_status": "pending"
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Order cannot be cancelled (already preparing/delivered)
  - `404 Not Found`: Order not found

**Error Handling:**
- Handle order not found
- Validate cancellation eligibility
- Show cancellation restrictions
- Display refund information

---

### 14. Order Tracking Screen

**Purpose/Functionality:**
- Real-time order tracking with map view
- Shows order status timeline
- Displays delivery person location (if assigned)
- Estimated time of arrival

**User Actions:**
- View order location on map
- Track delivery person (if assigned)
- View status timeline
- Contact delivery person
- View estimated delivery time

**API Endpoints:**

#### Get Order ETA
- **Method:** `GET`
- **Endpoint:** `/api/orders/{id}/eta/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "order_id": "uuid",
    "estimated_delivery_time": "2024-01-15T12:30:00Z",
    "current_status": "out_for_delivery",
    "delivery_person": {
      "id": "uuid",
      "name": "John Doe",
      "phone": "+919876543210",
      "location": {
        "latitude": 19.0760,
        "longitude": 72.8777
      }
    }
  }
  ```

**Error Handling:**
- Handle missing location data
- Show error if delivery person not assigned
- Display "Tracking unavailable" message

---

### 15. Order Rating Screen

**Purpose/Functionality:**
- Allows customers to rate and review completed orders
- Submit ratings for food quality, delivery, packaging
- Write detailed reviews

**User Actions:**
- Rate order (overall, food quality, delivery, packaging)
- Write review comment
- Upload photos (optional)
- Submit rating

**API Endpoints:**

#### Create Order Review
- **Method:** `POST`
- **Endpoint:** `/api/orders/{id}/review/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "overall_rating": 5,
    "food_quality_rating": 5,
    "delivery_rating": 4,
    "packaging_rating": 5,
    "comment": "Great food and fast delivery!",
    "images": ["base64_encoded_image"]
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "id": "uuid",
    "order": "uuid",
    "overall_rating": 5,
    "food_quality_rating": 5,
    "delivery_rating": 4,
    "packaging_rating": 5,
    "comment": "Great food and fast delivery!",
    "created_on": "2024-01-15T13:00:00Z"
  }
  ```
- **Error Responses:**
  - `400 Bad Request`: Order not completed or already reviewed
  - `404 Not Found`: Order not found

**Error Handling:**
- Validate rating values (1-5)
- Check if order is completed
- Prevent duplicate reviews
- Handle image upload errors

---

## Profile & Account Screens

### 16. Profile Screen

**Purpose/Functionality:**
- Displays customer profile information
- Allows editing profile details
- Manages account settings
- Access to addresses, payment methods, orders

**User Actions:**
- View profile information
- Edit profile (name, email, phone, photo)
- Change password
- Manage addresses
- View order history
- Logout

**API Endpoints:**

#### Get User Profile
- **Method:** `GET`
- **Endpoint:** `/api/users/profile/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "email": "user@example.com",
    "phone_number": "+919876543210",
    "first_name": "John",
    "last_name": "Doe",
    "profile_picture": "https://example.com/profile.jpg",
    "date_joined": "2024-01-01T00:00:00Z"
  }
  ```

#### Update User Profile
- **Method:** `PATCH`
- **Endpoint:** `/api/users/profile/update/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "first_name": "John",
    "last_name": "Doe",
    "email": "newemail@example.com"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "email": "newemail@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
  ```

#### Upload Profile Picture
- **Method:** `POST`
- **Endpoint:** `/api/profile/upload-picture/`
- **Authentication:** Required
- **Request Body:** `multipart/form-data`
  - `profile_picture`: Image file
- **Response (200 OK):**
  ```json
  {
    "profile_picture": "https://example.com/profile.jpg"
  }
  ```

#### Change Password
- **Method:** `POST`
- **Endpoint:** `/api/profile/change-password/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "old_password": "oldpassword123",
    "new_password": "newpassword123"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "message": "Password changed successfully"
  }
  ```

**Error Handling:**
- Validate email format
- Check password strength
- Handle duplicate email errors
- Validate image file size and format

---

### 17. Address Management Screen

**Purpose/Functionality:**
- Lists all saved delivery addresses
- Allows adding, editing, and deleting addresses
- Set default address

**User Actions:**
- View saved addresses
- Add new address
- Edit existing address
- Delete address
- Set default address

**API Endpoints:**

#### List Addresses
- **Method:** `GET`
- **Endpoint:** `/api/addresses/`
- **Authentication:** Required
- **Response (200 OK):**
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

#### Update Address
- **Method:** `PATCH`
- **Endpoint:** `/api/addresses/{id}/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "title": "Work",
    "address_line_1": "456 Business Ave",
    "is_default": true
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "id": 1,
    "title": "Work",
    "address_line_1": "456 Business Ave"
  }
  ```

#### Delete Address
- **Method:** `DELETE`
- **Endpoint:** `/api/addresses/{id}/`
- **Authentication:** Required
- **Response (204 No Content)**

**Error Handling:**
- Validate address fields
- Prevent deleting default address if it's the only one
- Handle geocoding errors

---

### 18. Customer Dashboard Screen

**Purpose/Functionality:**
- Overview of customer activity
- Quick access to recent orders
- Wallet balance and transactions
- Notifications and offers

**User Actions:**
- View dashboard summary
- Access recent orders
- Check wallet balance
- View notifications
- Browse offers and promotions

**API Endpoints:**

#### Get Wallet Balance
- **Method:** `GET`
- **Endpoint:** `/api/wallet/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "balance": 500.00,
    "currency": "INR"
  }
  ```

#### Get Wallet Transactions
- **Method:** `GET`
- **Endpoint:** `/api/wallet/transactions/`
- **Authentication:** Required
- **Query Parameters:**
  - `page`: Page number
  - `page_size`: Items per page
- **Response (200 OK):**
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

#### Get Notifications
- **Method:** `GET`
- **Endpoint:** `/api/notifications/`
- **Authentication:** Required
- **Query Parameters:**
  - `page`: Page number
  - `is_read`: Filter by read status
- **Response (200 OK):**
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

#### Mark All Notifications as Read
- **Method:** `POST`
- **Endpoint:** `/api/notifications/mark-all-read/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "message": "All notifications marked as read"
  }
  ```

**Error Handling:**
- Handle empty states
- Show loading indicators
- Display error messages

---

## Payment Screens

### 19. Payment Screen

**Purpose/Functionality:**
- Processes online payments
- Integrates with payment gateways (Paytm, Razorpay)
- Handles payment verification
- Shows payment status

**User Actions:**
- Select payment method
- Enter payment details
- Confirm payment
- View payment status
- Retry failed payments

**API Endpoints:**

#### Create Paytm Order
- **Method:** `POST`
- **Endpoint:** `/api/payments/paytm/create-order/`
- **Authentication:** Required
- **Request Body:**
  ```json
  {
    "order_id": "order-uuid"
  }
  ```
- **Response (200 OK):**
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

#### Verify Payment
- **Method:** `POST`
- **Endpoint:** `/api/payments/paytm/verify/`
- **Authentication:** Required
- **Request Body (Form Data):**
  ```
  ORDERID=ORDER_ORD-2024-001_1234567890
  TXNID=TXN123456
  STATUS=TXN_SUCCESS
  CHECKSUMHASH=checksum_hash
  ```
- **Response (200 OK):**
  ```json
  {
    "status": "success",
    "order_id": "order-uuid",
    "order_number": "ORD-2024-001",
    "payment_id": "TXN123456"
  }
  ```

#### Get Payment Details
- **Method:** `GET`
- **Endpoint:** `/api/payments/{id}/`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "id": "uuid",
    "order": {
      "id": "uuid",
      "order_number": "ORD-2024-001"
    },
    "amount": 623.00,
    "payment_method": "paytm",
    "payment_status": "completed",
    "transaction_id": "TXN123456",
    "created_on": "2024-01-15T10:30:00Z"
  }
  ```

**Error Handling:**
- Handle payment gateway errors
- Show payment failure messages
- Retry failed payments
- Handle network timeouts
- Validate payment amounts

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
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

### Error Response Format
```json
{
  "error": "Error message",
  "detail": "Detailed error description",
  "code": "ERROR_CODE"
}
```

### Best Practices
1. Always include `Authorization: Bearer {access_token}` header for authenticated requests
2. Handle token expiration and refresh automatically
3. Implement retry logic for network errors
4. Show user-friendly error messages
5. Log errors for debugging
6. Validate input before API calls
7. Handle offline scenarios gracefully

---

## WebSocket Support

### Real-time Order Updates
- **WebSocket URL:** `ws://your-domain.com/ws/orders/`
- **Authentication:** JWT token in query parameter or header
- **Events:**
  - `order_status_update`: Order status changed
  - `delivery_update`: Delivery status changed
  - `payment_update`: Payment status changed

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
- Image URLs may require authentication headers
- Pagination is supported on list endpoints
- Rate limiting may apply to certain endpoints
- Always validate responses before using data

