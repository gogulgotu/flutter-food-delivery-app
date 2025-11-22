# Checkout Process Documentation

## Overview

This document provides a comprehensive explanation of the checkout page process, including all API endpoints used, the complete checkout flow, and detailed information about each step in the order placement process.

---

## Table of Contents

1. [Checkout Flow Overview](#checkout-flow-overview)
2. [Step-by-Step Process](#step-by-step-process)
3. [API Endpoints Used](#api-endpoints-used)
4. [Special Cases](#special-cases)
5. [Error Handling](#error-handling)
6. [Payment Flow](#payment-flow)

---

## Checkout Flow Overview

The checkout process is a **two-step flow**:

1. **Step 1: Delivery Address & Location** - User selects/creates delivery address and provides GPS location
2. **Step 2: Payment Method** - User selects payment method and places order

### Key Requirements

- **Authentication Required**: User must be logged in
- **Cart Must Have Items**: Cannot checkout with empty cart
- **Location Mandatory**: GPS coordinates must be collected before proceeding
- **Address Required**: Delivery address must be selected or created
- **Meat Order Scheduling**: Orders with meat products require Saturday/Sunday scheduling (6 AM - 8 AM)

---

## Step-by-Step Process

### Step 1: Delivery Address & Location Selection

#### 1.1 Location Collection (Mandatory)

**Purpose:** Collect GPS coordinates for accurate delivery tracking and fee calculation.

**Process:**
1. On page load, system checks for existing location in localStorage
2. If no location found, shows location collection modal after 2 seconds
3. User can collect location via:
   - **GPS** (most accurate)
   - **Address Geocoding** (convert address to coordinates)
   - **Map Selection** (using InlineLocationSelector component)
   - **Automatic Fallback** (tries all methods automatically)

**Location Validation:**
- Coordinates must be valid (latitude: -90 to 90, longitude: -180 to 180)
- Location must be within service area (if applicable)
- Location accuracy is checked

**Storage:**
- Location saved to localStorage with timestamp
- Location saved to backend via location service
- Location associated with selected address

#### 1.2 Address Management

**User Actions:**
- View saved addresses
- Select existing address
- Add new address
- Edit existing address
- Delete address
- Set default address

**Address Selection Flow:**
1. System loads user's saved addresses
2. Default address is auto-selected (or first address if no default)
3. User can select different address
4. If selected address lacks coordinates, system attempts to:
   - Geocode address to get coordinates
   - Update address with coordinates (non-blocking)
   - Use coordinates from selectedDeliveryLocation

#### 1.3 Proceed to Payment

**Validation Before Proceeding:**
- ✅ Location must be collected (latitude & longitude)
- ✅ Address must be selected
- ✅ Location coordinates must be valid
- ✅ Address should have coordinates (attempts update if missing)

**Actions:**
- Updates address with latest location coordinates (if needed)
- Validates all required data
- Moves to Step 2 (Payment Method)

---

### Step 2: Payment Method Selection

#### 2.1 Payment Method Selection

**Available Payment Methods:**
- **Paytm (Online Payment)**: Pay via Paytm payment gateway
- **COD (Cash on Delivery)**: Pay when order is delivered

**User Actions:**
- Select payment method (radio button)
- View order summary
- Optionally schedule delivery (for non-meat orders)

#### 2.2 Scheduling Options

**For Meat Orders:**
- **Mandatory**: Must schedule for Saturday or Sunday
- **Time Window**: 6:00 AM - 8:00 AM (fixed)
- **Date Selection**: Next available Saturday/Sunday

**For Non-Meat Orders:**
- **Optional**: Can schedule for later delivery
- **Date Selection**: Based on vendor operating hours
- **Time Selection**: Available time slots based on vendor hours
- **Validation**: Must be in the future and within operating hours

#### 2.3 Place Order

**Order Creation Process:**
1. Validates all required data
2. Checks if meat products require scheduling
3. Builds order payload
4. Creates order via API
5. Handles payment based on selected method

**Payment Handling:**
- **COD**: Order created, redirects to order detail page
- **Paytm**: Creates Paytm order, redirects to Paytm payment page

---

## API Endpoints Used

### 1. Get User Addresses

**Endpoint:** `GET /api/addresses/`

**Method:** `GET`

**Authentication:** Required

**Purpose:** Fetch all saved delivery addresses for the user

**Response:**
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

**Used In:**
- Initial page load
- After address create/update/delete
- Address selection

---

### 2. Create Address

**Endpoint:** `POST /api/addresses/`

**Method:** `POST`

**Authentication:** Required

**Purpose:** Create a new delivery address

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
  "postal_code": "400001",
  "is_default": false
}
```

**Used In:**
- Adding new address from checkout page

---

### 3. Update Address

**Endpoint:** `PATCH /api/addresses/{id}/`

**Method:** `PATCH`

**Authentication:** Required

**Purpose:** Update existing address or add coordinates to address

**Request Body:**
```json
{
  "title": "Work",
  "address_line_1": "456 Business Ave",
  "latitude": 19.0760,
  "longitude": 72.8777,
  "is_default": true
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "title": "Work",
  "address_line_1": "456 Business Ave",
  "latitude": 19.0760,
  "longitude": 72.8777,
  "is_default": true
}
```

**Used In:**
- Editing address details
- Updating address with GPS coordinates
- Setting default address

---

### 4. Delete Address

**Endpoint:** `DELETE /api/addresses/{id}/`

**Method:** `DELETE`

**Authentication:** Required

**Purpose:** Delete a delivery address

**Response (204 No Content)**

**Used In:**
- Removing unwanted addresses

**Note:** Cannot delete if it's the only address

---

### 5. Get Vendor Details (with Operating Hours)

**Endpoint:** `GET /api/vendors/{slug}/` or `GET /api/vendors/{id}/`

**Method:** `GET`

**Authentication:** Not required (but user context may be used)

**Purpose:** Get vendor information including operating hours for scheduling

**Response:**
```json
{
  "id": "uuid",
  "name": "Pizza Palace",
  "operating_hours": [
    {
      "day_number": 1,
      "day_name": "Monday",
      "opening_time": "09:00:00",
      "closing_time": "22:00:00",
      "break_start_time": "14:00:00",
      "break_end_time": "15:00:00",
      "is_open": true
    }
  ]
}
```

**Used In:**
- Fetching operating hours for scheduling
- Validating delivery time slots

---

### 6. Geocode Address (Convert Address to Coordinates)

**Endpoint:** `POST /api/location/geocode/`

**Method:** `POST`

**Authentication:** Required

**Purpose:** Convert address string to GPS coordinates

**Request Body:**
```json
{
  "address": "123 Main St, Mumbai, Maharashtra, 400001"
}
```

**Response (200 OK):**
```json
{
  "latitude": 19.0760,
  "longitude": 72.8777,
  "formatted_address": "123 Main St, Mumbai, Maharashtra 400001, India"
}
```

**Used In:**
- Converting manual address input to coordinates
- Getting coordinates for addresses without GPS data

---

### 7. Reverse Geocode (Convert Coordinates to Address)

**Endpoint:** `POST /api/location/reverse-geocode/`

**Method:** `POST`

**Authentication:** Required

**Purpose:** Convert GPS coordinates to address string

**Request Body:**
```json
{
  "latitude": 19.0760,
  "longitude": 72.8777
}
```

**Response (200 OK):**
```json
{
  "address": "123 Main St, Mumbai, Maharashtra 400001, India",
  "latitude": 19.0760,
  "longitude": 72.8777
}
```

**Used In:**
- Converting GPS location to readable address
- Displaying address for collected GPS coordinates

---

### 8. Save Location

**Endpoint:** `POST /api/location/save/`

**Method:** `POST`

**Authentication:** Required

**Purpose:** Save user's current location to backend

**Request Body:**
```json
{
  "latitude": 19.0760,
  "longitude": 72.8777,
  "address": "123 Main St, Mumbai",
  "accuracy": 10.5
}
```

**Response (200 OK):**
```json
{
  "message": "Location saved successfully",
  "location_id": "uuid"
}
```

**Used In:**
- Saving collected GPS location
- Storing location for delivery tracking

---

### 9. Create Order

**Endpoint:** `POST /api/orders/`

**Method:** `POST`

**Authentication:** Required

**Purpose:** Create a new order with items, address, and payment method

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
  "payment_status": "pending",
  "scheduled_delivery_time": "2024-01-15T12:00:00Z",
  "customer_latitude": 19.0760,
  "customer_longitude": 72.8777
}
```

**Response (201 Created):**
```json
{
  "id": "uuid",
  "order_number": "ORD-2024-001",
  "vendor": {
    "id": "uuid",
    "name": "Pizza Palace"
  },
  "delivery_address": {
    "id": 1,
    "title": "Home",
    "address_line_1": "123 Main St"
  },
  "items": [
    {
      "id": "uuid",
      "product": {
        "id": "uuid",
        "name": "Margherita Pizza"
      },
      "quantity": 2,
      "unit_price": 299.00,
      "total_price": 598.00
    }
  ],
  "subtotal": 598.00,
  "delivery_fee": 25.00,
  "tax": 29.90,
  "total_amount": 652.90,
  "order_status": "pending",
  "payment_status": "pending",
  "delivery_status": "pending",
  "order_placed_at": "2024-01-15T10:30:00Z",
  "estimated_delivery_time": "2024-01-15T12:15:00Z",
  "scheduled_delivery_time": "2024-01-15T12:00:00Z"
}
```

**Validation:**
- ✅ Order must contain at least one item
- ✅ Vendor must exist and be active
- ✅ Delivery address must belong to user
- ✅ All products must be available
- ✅ Meat orders must have scheduled_delivery_time (Saturday/Sunday, 6-8 AM)
- ✅ Scheduled time must be in the future (for non-meat orders)
- ✅ Total amount must match calculated total

**Used In:**
- Creating order when user clicks "Place Order"
- Re-creating order if payment method or address changes

---

### 10. Create Paytm Payment Order

**Endpoint:** `POST /api/payments/paytm/create-order/`

**Method:** `POST`

**Authentication:** Required

**Purpose:** Create Paytm payment order for online payment

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
  "order_number": "ORD-2024-001",
  "paytm_order_id": "ORDER_ORD-2024-001_1234567890",
  "paytm_merchant_id": "MERCHANT_ID",
  "paytm_params": {
    "MID": "MERCHANT_ID",
    "ORDER_ID": "ORDER_ORD-2024-001_1234567890",
    "TXN_AMOUNT": "623.00",
    "CUST_ID": "user-uuid",
    "INDUSTRY_TYPE_ID": "Retail",
    "CHANNEL_ID": "WAP",
    "WEBSITE": "WEBSTAGING",
    "CALLBACK_URL": "http://localhost:3000/payment/paytm/callback",
    "CHECKSUMHASH": "checksum_hash_here"
  },
  "paytm_url": "https://securegw-stage.paytm.in/theia/processTransaction",
  "amount": 623.00
}
```

**Used In:**
- Initiating Paytm payment when user selects "Pay Online"
- Redirects user to Paytm payment gateway

**Note:** Frontend creates a form with Paytm parameters and auto-submits to Paytm URL

---

### 11. Verify Paytm Payment

**Endpoint:** `POST /api/payments/paytm/verify/`

**Method:** `POST`

**Authentication:** Required (or AllowAny for callback)

**Purpose:** Verify Paytm payment after user completes payment

**Request Body (Form Data from Paytm):**
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
  "payment_id": "TXN123456",
  "message": "Payment verified successfully"
}
```

**Used In:**
- Paytm callback page after payment
- Verifying payment status
- Updating order payment status

---

## Special Cases

### 1. Meat Orders

**Requirements:**
- Must be scheduled for **Saturday or Sunday only**
- Delivery window: **6:00 AM - 8:00 AM** (fixed)
- Cannot use general scheduling modal
- Scheduling is **mandatory** (cannot place immediate order)

**Flow:**
1. User adds meat product to cart
2. On checkout, system detects meat products
3. Shows meat-specific scheduling modal
4. User selects Saturday or Sunday
5. Time is automatically set to 6:00 AM
6. Order is created with scheduled_delivery_time

**API Validation:**
- Backend validates scheduled_delivery_time is Saturday/Sunday
- Backend validates time is between 6 AM - 8 AM
- Returns error if validation fails

---

### 2. Scheduled Delivery (Non-Meat Orders)

**Requirements:**
- Optional scheduling for non-meat orders
- Date selection based on vendor operating hours
- Time slots based on vendor opening/closing times
- Must be in the future
- Must be within vendor operating hours

**Flow:**
1. User checks "Schedule delivery for later"
2. System fetches vendor operating hours
3. Shows available dates (next 14 days, only open days)
4. User selects date
5. System shows available time slots (30-minute intervals)
6. User selects time
7. Order created with scheduled_delivery_time

**Time Slot Generation:**
- Based on vendor operating hours
- 30-minute intervals
- Excludes break times
- Only shows slots within operating hours

---

### 3. Location Collection

**Mandatory Requirement:**
- Location must be collected before proceeding to payment
- Location must be collected before placing order
- Coordinates are required for delivery tracking

**Collection Methods (in priority order):**
1. **GPS** - Most accurate, requires permission
2. **Map Selection** - User picks location on map
3. **Address Geocoding** - Convert address to coordinates
4. **IP-based** - Fallback (less accurate)

**Storage:**
- Saved to localStorage (with timestamp)
- Saved to backend via location service
- Associated with selected address
- Included in order payload (customer_latitude, customer_longitude)

**Validation:**
- Coordinates must be valid numbers
- Latitude: -90 to 90
- Longitude: -180 to 180
- Location must be within service area (if applicable)

---

### 4. Address Coordinate Sync

**Process:**
- When address is selected, system checks if it has coordinates
- If missing, attempts to geocode address
- Updates address with coordinates (non-blocking)
- If update fails, coordinates are sent directly in order payload

**Fallback:**
- If address update fails, coordinates are included in order creation
- Order contains both `delivery_address` (ID) and `customer_latitude`/`customer_longitude`
- Ensures delivery tracking works even if address update fails

---

## Error Handling

### Common Errors

#### 1. Location Not Collected
- **Error:** "Delivery location is required"
- **Action:** Shows location collection modal
- **Resolution:** User must collect location before proceeding

#### 2. Invalid Location Coordinates
- **Error:** "Invalid location coordinates"
- **Action:** Prompts user to collect location again
- **Resolution:** Re-collect location using GPS or map

#### 3. Address Not Selected
- **Error:** "Please select a delivery address"
- **Action:** Blocks proceeding to payment
- **Resolution:** User must select or create address

#### 4. Meat Order Without Scheduling
- **Error:** "Meat orders must be scheduled for Saturday or Sunday"
- **Action:** Shows meat scheduling modal
- **Resolution:** User must select Saturday or Sunday

#### 5. Order Creation Failed
- **Error:** Various validation errors
- **Common Causes:**
  - Product no longer available
  - Vendor is closed
  - Invalid scheduled time
  - Cart items changed
- **Resolution:** Refresh cart, check product availability, retry

#### 6. Payment Initiation Failed
- **Error:** "Failed to initiate payment"
- **Action:** Shows error message, allows retry
- **Resolution:** Check payment gateway status, retry payment

#### 7. Address Update Failed
- **Error:** Silent failure (non-blocking)
- **Action:** Coordinates sent directly in order payload
- **Resolution:** Order still created successfully

---

## Payment Flow

### Cash on Delivery (COD)

**Flow:**
1. User selects "Cash on Delivery"
2. Clicks "Place Order"
3. Order created with `payment_method: "cod"` and `payment_status: "pending"`
4. Cart cleared
5. Redirect to order detail page
6. Payment collected on delivery

**No Additional API Calls:**
- Order creation is sufficient
- Payment status updated when delivery person collects payment

---

### Paytm Online Payment

**Flow:**
1. User selects "Pay Online (Paytm)"
2. Clicks "Pay with Paytm"
3. Order created (if not already created)
4. **API Call:** `POST /api/payments/paytm/create-order/` with order_id
5. Receives Paytm payment parameters
6. Frontend creates hidden form with Paytm parameters
7. Auto-submits form to Paytm payment gateway
8. User redirected to Paytm payment page
9. User completes payment on Paytm
10. Paytm redirects to callback URL: `/payment/paytm/callback`
11. **API Call:** `POST /api/payments/paytm/verify/` with payment response
12. Payment verified, order status updated
13. Redirect to order detail page

**Payment Verification:**
- Paytm sends payment response to callback URL
- Backend verifies checksum
- Updates payment status to "completed"
- Updates order payment_status
- Sends notifications

---

## Order Creation Payload Details

### Required Fields

```json
{
  "vendor": "vendor-uuid",              // Required: Vendor ID
  "delivery_address": 1,                // Required: Address ID
  "items": [                            // Required: At least one item
    {
      "product": "product-uuid",        // Required: Product ID
      "quantity": 2,                    // Required: Quantity
      "price": 299.00                   // Required: Unit price
    }
  ],
  "subtotal": 598.00,                   // Required: Subtotal
  "delivery_fee": 25.00,                // Required: Delivery fee
  "total_amount": 623.00,               // Required: Total amount
  "payment_method": "cod",               // Required: Payment method
  "payment_status": "pending"           // Required: Initial payment status
}
```

### Optional Fields

```json
{
  "scheduled_delivery_time": "2024-01-15T12:00:00Z",  // Optional: For scheduled orders
  "customer_latitude": 19.0760,                       // Optional: GPS latitude
  "customer_longitude": 72.8777,                      // Optional: GPS longitude
  "special_instructions": "Ring doorbell"             // Optional: Delivery instructions
}
```

### Backend Processing

1. **Validates Items:**
   - Checks product exists and is available
   - Validates quantity > 0
   - Recalculates prices (prevents frontend manipulation)

2. **Validates Vendor:**
   - Checks vendor exists and is active
   - Validates vendor is accepting orders

3. **Validates Address:**
   - Checks address belongs to user
   - Validates address is complete

4. **Validates Scheduling:**
   - For meat orders: validates Saturday/Sunday, 6-8 AM
   - For other orders: validates future time

5. **Calculates Totals:**
   - Recalculates subtotal from items
   - Applies delivery fee
   - Calculates tax (5%)
   - Validates total matches frontend calculation

6. **Creates Order:**
   - Creates Order record
   - Creates OrderItem records
   - Sets initial order status
   - Sets delivery status
   - Creates payment record (if online payment)

7. **Sends Notifications:**
   - Notifies vendor of new order
   - Notifies user of order confirmation
   - Triggers order assignment process

---

## Complete Checkout Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CHECKOUT PAGE LOAD                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Check Authentication         │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Check Cart Has Items         │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Load User Addresses          │
        │  GET /api/addresses/          │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Check Location               │
        │  (from localStorage/backend)  │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  No Location?                 │
        │  Show Location Modal           │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Collect Location             │
        │  - GPS                        │
        │  - Geocode                    │
        │  - Map Selection              │
        │  POST /api/location/save/     │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  STEP 1: Address Selection    │
        │  - Select/Create Address      │
        │  - Update with Coordinates    │
        │  PATCH /api/addresses/{id}/   │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Click "Continue to Payment"  │
        │  Validates Location & Address  │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  STEP 2: Payment Method        │
        │  - Select Payment Method      │
        │  - Optional: Schedule Delivery│
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Check for Meat Products      │
        └───────────────┬───────────────┘
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
    ┌───────────────┐      ┌───────────────┐
    │ Has Meat?     │      │ No Meat       │
    │ Show Meat     │      │ Optional      │
    │ Scheduling    │      │ Scheduling    │
    └───────┬───────┘      └───────┬───────┘
            │                       │
            └───────────┬───────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Click "Place Order"           │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Create Order                 │
        │  POST /api/orders/            │
        └───────────────┬───────────────┘
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
    ┌───────────────┐      ┌───────────────┐
    │ Payment Method│      │ Payment Method│
    │ = COD         │      │ = Paytm       │
    └───────┬───────┘      └───────┬───────┘
            │                       │
            ▼                       ▼
    ┌───────────────┐      ┌───────────────┐
    │ Clear Cart    │      │ Create Paytm  │
    │ Redirect to   │      │ Order         │
    │ Order Detail  │      │ POST /api/    │
    │               │      │ payments/     │
    │               │      │ paytm/        │
    │               │      │ create-order/ │
    └───────────────┘      └───────┬───────┘
                                    │
                                    ▼
                            ┌───────────────┐
                            │ Redirect to   │
                            │ Paytm Gateway │
                            └───────┬───────┘
                                    │
                                    ▼
                            ┌───────────────┐
                            │ User Pays on  │
                            │ Paytm         │
                            └───────┬───────┘
                                    │
                                    ▼
                            ┌───────────────┐
                            │ Paytm Callback│
                            │ POST /api/    │
                            │ payments/     │
                            │ paytm/verify/ │
                            └───────┬───────┘
                                    │
                                    ▼
                            ┌───────────────┐
                            │ Redirect to   │
                            │ Order Detail  │
                            └───────────────┘
```

---

## Key Features

### 1. Order Reuse Logic

The system implements smart order reuse:
- If order already exists with same payment method, address, and total → reuses order
- If payment method changes → creates new order
- If address changes → creates new order
- If cart total changes → creates new order
- If order already paid → creates new order

### 2. Location Persistence

- Location saved to localStorage (1 hour validity)
- Location saved to backend
- Location associated with address
- Location included in order payload

### 3. Address Coordinate Sync

- Attempts to update address with coordinates
- Non-blocking (doesn't fail checkout if update fails)
- Coordinates sent directly in order if address update fails
- Ensures delivery tracking always works

### 4. Vendor Operating Hours Integration

- Fetches vendor operating hours for scheduling
- Only shows dates when vendor is open
- Generates time slots based on operating hours
- Excludes break times from available slots

---

## Best Practices

1. **Always validate location before proceeding**
2. **Update address coordinates when possible**
3. **Handle payment failures gracefully**
4. **Show clear error messages**
5. **Provide fallback options for location collection**
6. **Validate all data before API calls**
7. **Handle network errors with retry logic**
8. **Clear cart only after successful order creation**
9. **Invalidate cache after order creation**
10. **Provide loading states for all async operations**

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- All monetary values are in INR (Indian Rupees)
- Location coordinates are in decimal degrees (WGS84)
- Tax is calculated as 5% of subtotal
- Delivery fee is set by vendor
- Order number is auto-generated (format: ORD-YYYY-XXX)
- Payment verification happens asynchronously
- Order status updates via WebSocket (real-time)

