# Address API Documentation

## Overview

The Address API provides comprehensive functionality for managing user delivery addresses. It supports creating, reading, updating, and deleting addresses, with features like default address management, GPS coordinate validation, and search capabilities.

**Base URL:** `/api/addresses/`

**Authentication:** All endpoints require authentication (JWT token)

---

## Table of Contents

1. [Address Model Structure](#address-model-structure)
2. [API Endpoints](#api-endpoints)
3. [Request/Response Formats](#requestresponse-formats)
4. [Special Features](#special-features)
5. [Error Handling](#error-handling)
6. [Use Cases](#use-cases)
7. [Code Examples](#code-examples)

---

## Address Model Structure

### Address Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | Integer | Auto | Primary key, auto-generated |
| `title` | String (max 100) | Yes | Address label (e.g., "Home", "Work", "Office") |
| `address_line_1` | String (max 200) | Yes | Primary address line |
| `address_line_2` | String (max 200) | No | Secondary address line (apartment, floor, etc.) |
| `city` | String (max 100) | Yes | City name |
| `state` | String (max 100) | Yes | State/Province name |
| `country` | String (max 100) | Yes | Country name |
| `postal_code` | String (max 20) | Yes | Postal/ZIP code |
| `latitude` | Decimal (9,6) | No | GPS latitude coordinate |
| `longitude` | Decimal (9,6) | No | GPS longitude coordinate |
| `is_default` | Boolean | No | Whether this is the default address (default: false) |
| `created_on` | DateTime | Auto | Creation timestamp |
| `updated_on` | DateTime | Auto | Last update timestamp |

### Address Ordering

Addresses are automatically ordered by:
1. **Default address first** (`is_default = true`)
2. **Most recently created** (descending)

---

## API Endpoints

### 1. List All Addresses

**Endpoint:** `GET /api/addresses/`

**Method:** `GET`

**Authentication:** Required

**Description:** Retrieves all active addresses for the authenticated user. Only returns addresses with active record status.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search` | String | No | Search in title, address_line_1, city, state |
| `ordering` | String | No | Order by field (`is_default`, `created_on`, `-is_default`, `-created_on`) |

**Example Request:**
```http
GET /api/addresses/?search=mumbai&ordering=-is_default
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
[
  {
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
  {
    "id": 2,
    "title": "Work",
    "address_line_1": "456 Business Avenue",
    "address_line_2": "Floor 5",
    "city": "Mumbai",
    "state": "Maharashtra",
    "country": "India",
    "postal_code": "400002",
    "latitude": "19.082000",
    "longitude": "72.880000",
    "is_default": false
  }
]
```

**Response (Empty List - 200 OK):**
```json
[]
```

**Notes:**
- Only returns addresses with `record_status = active` (status_code = 1)
- Default address appears first in the list
- Search is case-insensitive
- Supports partial matching

---

### 2. Create New Address

**Endpoint:** `POST /api/addresses/`

**Method:** `POST`

**Authentication:** Required

**Description:** Creates a new delivery address for the authenticated user. Automatically handles default address logic.

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | String | Yes | Address label |
| `address_line_1` | String | Yes | Primary address |
| `address_line_2` | String | No | Secondary address |
| `city` | String | Yes | City name |
| `state` | String | Yes | State name |
| `country` | String | Yes | Country name |
| `postal_code` | String | Yes | Postal code |
| `latitude` | Decimal/String | No | GPS latitude |
| `longitude` | Decimal/String | No | GPS longitude |
| `is_default` | Boolean | No | Set as default (default: false) |

**Example Request:**
```http
POST /api/addresses/
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
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
}
```

**Response (201 Created):**
```json
{
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
}
```

**Special Behavior:**
- If `is_default = true`, all other addresses for the user are automatically set to `is_default = false`
- Address is automatically assigned to the authenticated user
- `record_status` is automatically set to active
- `created_by` is automatically set to the authenticated user

**Validation Rules:**
- `title`: Required, max 100 characters
- `address_line_1`: Required, max 200 characters
- `address_line_2`: Optional, max 200 characters
- `city`: Required, max 100 characters
- `state`: Required, max 100 characters
- `country`: Required, max 100 characters
- `postal_code`: Required, max 20 characters
- `latitude`: Optional, must be between -90 and 90
- `longitude`: Optional, must be between -180 and 180
- If `latitude` is provided, `longitude` must also be provided (and vice versa)

**Error Responses:**

**400 Bad Request - Missing Required Field:**
```json
{
  "title": ["This field is required."],
  "address_line_1": ["This field is required."]
}
```

**400 Bad Request - Invalid Coordinates:**
```json
{
  "error": "Both latitude and longitude must be provided together"
}
```

**400 Bad Request - Invalid Coordinate Values:**
```json
{
  "error": "Invalid coordinates: Latitude must be between -90 and 90"
}
```

---

### 3. Get Address Details

**Endpoint:** `GET /api/addresses/{id}/`

**Method:** `GET`

**Authentication:** Required

**Description:** Retrieves details of a specific address by ID. Only returns addresses belonging to the authenticated user.

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | Yes | Address ID |

**Example Request:**
```http
GET /api/addresses/1/
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**
```json
{
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
}
```

**Error Responses:**

**404 Not Found:**
```json
{
  "detail": "Not found."
}
```

**403 Forbidden** (if address belongs to another user):
```json
{
  "detail": "You do not have permission to perform this action."
}
```

---

### 4. Update Address

**Endpoint:** `PATCH /api/addresses/{id}/` or `PUT /api/addresses/{id}/`

**Method:** `PATCH` (partial update) or `PUT` (full update)

**Authentication:** Required

**Description:** Updates an existing address. Supports partial updates (PATCH) or full updates (PUT). Automatically handles default address logic and coordinate validation.

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | Yes | Address ID |

**Request Body:** (All fields optional for PATCH, all required for PUT)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | String | No | Address label |
| `address_line_1` | String | No | Primary address |
| `address_line_2` | String | No | Secondary address |
| `city` | String | No | City name |
| `state` | String | No | State name |
| `country` | String | No | Country name |
| `postal_code` | String | No | Postal code |
| `latitude` | Decimal/String | No | GPS latitude |
| `longitude` | Decimal/String | No | GPS longitude |
| `is_default` | Boolean | No | Set as default |

**Example Request (PATCH - Partial Update):**
```http
PATCH /api/addresses/1/
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "title": "My Home",
  "is_default": true
}
```

**Example Request (PUT - Full Update):**
```http
PUT /api/addresses/1/
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
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
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "title": "My Home",
  "address_line_1": "123 Main Street",
  "address_line_2": "Apt 4B",
  "city": "Mumbai",
  "state": "Maharashtra",
  "country": "India",
  "postal_code": "400001",
  "latitude": "19.076000",
  "longitude": "72.877700",
  "is_default": true
}
```

**Special Behavior:**
- If `is_default` is changed to `true`, all other addresses for the user are automatically set to `is_default = false`
- Coordinates are validated if provided
- If only one coordinate (latitude or longitude) is provided, returns 400 error
- Coordinates are validated for valid ranges (-90 to 90 for latitude, -180 to 180 for longitude)
- After update, coordinates are re-validated

**Validation Rules:**
- Same as Create Address
- For PATCH: Only provided fields are validated
- For PUT: All fields must be provided

**Error Responses:**

**400 Bad Request - Invalid Coordinates:**
```json
{
  "error": "Both latitude and longitude must be provided together"
}
```

**400 Bad Request - Invalid Coordinate Values:**
```json
{
  "error": "Invalid coordinates: Latitude must be between -90 and 90"
}
```

**404 Not Found:**
```json
{
  "detail": "Not found."
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to update address",
  "detail": "Error details (only in DEBUG mode)"
}
```

---

### 5. Delete Address

**Endpoint:** `DELETE /api/addresses/{id}/`

**Method:** `DELETE`

**Authentication:** Required

**Description:** Deletes an address. Only allows deletion of addresses belonging to the authenticated user.

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | Yes | Address ID |

**Example Request:**
```http
DELETE /api/addresses/1/
Authorization: Bearer <jwt_token>
```

**Response (204 No Content):**
```
(Empty response body)
```

**Error Responses:**

**404 Not Found:**
```json
{
  "detail": "Not found."
}
```

**403 Forbidden:**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

**Notes:**
- Address is soft-deleted (record_status is updated, not physically deleted)
- Deleted addresses are not returned in list queries
- Cannot delete if it's the only address (validation should be handled on frontend)

---

## Special Features

### 1. Default Address Management

**Automatic Default Handling:**
- When creating or updating an address with `is_default = true`, all other addresses for the user are automatically set to `is_default = false`
- This ensures only one default address exists per user
- Default address appears first in list responses

**Implementation:**
```python
# When creating/updating with is_default=True
if is_default:
    Address.objects.filter(
        user=request.user,
        is_default=True,
        record_status=active_status
    ).exclude(id=instance.id).update(is_default=False)
```

**Use Cases:**
- Setting a new default address
- Updating an existing address to be default
- Ensuring only one default address exists

---

### 2. GPS Coordinate Validation

**Coordinate Validation:**
- Coordinates are validated when provided
- Both latitude and longitude must be provided together
- Latitude must be between -90 and 90
- Longitude must be between -180 and 180
- Coordinates are validated using `MappingService.validate_coordinates()`

**Validation Rules:**
```python
# Both coordinates required together
if latitude is not None or longitude is not None:
    if (lat is not None and lng is None) or (lat is None and lng is not None):
        return error("Both latitude and longitude must be provided together")
    
    # Validate ranges
    is_valid, error_msg = MappingService.validate_coordinates(lat, lng)
    if not is_valid:
        return error(f"Invalid coordinates: {error_msg}")
```

**Use Cases:**
- Adding GPS coordinates when creating address
- Updating GPS coordinates for existing address
- Ensuring coordinate accuracy for delivery tracking

---

### 3. Search Functionality

**Search Fields:**
- `title` - Address label
- `address_line_1` - Primary address
- `city` - City name
- `state` - State name

**Search Behavior:**
- Case-insensitive
- Partial matching
- Searches across all specified fields

**Example:**
```http
GET /api/addresses/?search=mumbai
```
Returns all addresses containing "mumbai" in title, address_line_1, city, or state.

---

### 4. Ordering

**Default Ordering:**
1. Default address first (`is_default = true`)
2. Most recently created addresses first

**Custom Ordering:**
- `ordering=is_default` - Default addresses first
- `ordering=-is_default` - Non-default addresses first
- `ordering=created_on` - Oldest first
- `ordering=-created_on` - Newest first

**Example:**
```http
GET /api/addresses/?ordering=-created_on
```

---

### 5. Record Status Filtering

**Active Addresses Only:**
- Only addresses with `record_status = active` (status_code = 1) are returned
- Deleted/inactive addresses are automatically filtered out
- Ensures data consistency

---

## Error Handling

### Common Error Responses

#### 400 Bad Request

**Missing Required Fields:**
```json
{
  "title": ["This field is required."],
  "address_line_1": ["This field is required."],
  "city": ["This field is required."]
}
```

**Invalid Coordinates:**
```json
{
  "error": "Both latitude and longitude must be provided together"
}
```

**Invalid Coordinate Values:**
```json
{
  "error": "Invalid coordinates: Latitude must be between -90 and 90"
}
```

#### 401 Unauthorized

**Missing or Invalid Token:**
```json
{
  "detail": "Authentication credentials were not provided."
}
```

```json
{
  "detail": "Given token not valid for any token type"
}
```

#### 403 Forbidden

**Accessing Another User's Address:**
```json
{
  "detail": "You do not have permission to perform this action."
}
```

#### 404 Not Found

**Address Not Found:**
```json
{
  "detail": "Not found."
}
```

#### 500 Internal Server Error

**Server Error:**
```json
{
  "error": "Failed to update address",
  "detail": "Error details (only in DEBUG mode)"
}
```

---

## Use Cases

### 1. Adding a New Address

**Scenario:** User wants to add a new delivery address.

**Steps:**
1. Collect address details from user
2. Optionally collect GPS coordinates
3. Call `POST /api/addresses/` with address data
4. If setting as default, include `is_default: true`
5. Display success message and refresh address list

**Example:**
```javascript
const newAddress = {
  title: "Home",
  address_line_1: "123 Main Street",
  address_line_2: "Apt 4B",
  city: "Mumbai",
  state: "Maharashtra",
  country: "India",
  postal_code: "400001",
  latitude: "19.076000",
  longitude: "72.877700",
  is_default: true
};

const response = await fetch('/api/addresses/', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(newAddress)
});
```

---

### 2. Setting Default Address

**Scenario:** User wants to change their default address.

**Steps:**
1. Get address ID to set as default
2. Call `PATCH /api/addresses/{id}/` with `is_default: true`
3. Backend automatically unsets other default addresses
4. Refresh address list

**Example:**
```javascript
const response = await fetch(`/api/addresses/${addressId}/`, {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ is_default: true })
});
```

---

### 3. Updating Address Coordinates

**Scenario:** User wants to update GPS coordinates for an address.

**Steps:**
1. Get current GPS coordinates (from device or map)
2. Call `PATCH /api/addresses/{id}/` with latitude and longitude
3. Backend validates coordinates
4. Update successful

**Example:**
```javascript
const response = await fetch(`/api/addresses/${addressId}/`, {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    latitude: "19.076000",
    longitude: "72.877700"
  })
});
```

---

### 4. Searching Addresses

**Scenario:** User wants to find addresses in a specific city.

**Steps:**
1. Call `GET /api/addresses/?search={query}`
2. Backend searches in title, address_line_1, city, state
3. Display filtered results

**Example:**
```javascript
const response = await fetch('/api/addresses/?search=mumbai', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

---

### 5. Deleting an Address

**Scenario:** User wants to remove an address.

**Steps:**
1. Confirm deletion with user
2. Call `DELETE /api/addresses/{id}/`
3. Backend soft-deletes address (updates record_status)
4. Refresh address list

**Example:**
```javascript
const response = await fetch(`/api/addresses/${addressId}/`, {
  method: 'DELETE',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

---

## Code Examples

### JavaScript/React Example

```javascript
// Address Service
class AddressService {
  constructor(apiClient) {
    this.api = apiClient;
  }

  // Get all addresses
  async getAllAddresses(search = null) {
    const url = search 
      ? `/api/addresses/?search=${encodeURIComponent(search)}`
      : '/api/addresses/';
    
    return await this.api.get(url);
  }

  // Get address by ID
  async getAddress(id) {
    return await this.api.get(`/api/addresses/${id}/`);
  }

  // Create address
  async createAddress(addressData) {
    return await this.api.post('/api/addresses/', addressData);
  }

  // Update address
  async updateAddress(id, addressData) {
    return await this.api.patch(`/api/addresses/${id}/`, addressData);
  }

  // Delete address
  async deleteAddress(id) {
    return await this.api.delete(`/api/addresses/${id}/`);
  }

  // Set default address
  async setDefaultAddress(id) {
    return await this.updateAddress(id, { is_default: true });
  }

  // Update coordinates
  async updateCoordinates(id, latitude, longitude) {
    return await this.updateAddress(id, { latitude, longitude });
  }
}

// Usage
const addressService = new AddressService(apiClient);

// Get all addresses
const addresses = await addressService.getAllAddresses();

// Create new address
const newAddress = await addressService.createAddress({
  title: "Home",
  address_line_1: "123 Main Street",
  city: "Mumbai",
  state: "Maharashtra",
  country: "India",
  postal_code: "400001",
  is_default: true
});

// Set default address
await addressService.setDefaultAddress(2);

// Update coordinates
await addressService.updateCoordinates(1, "19.076000", "72.877700");
```

---

### Python/Django Example

```python
import requests

class AddressAPI:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def get_all_addresses(self, search=None):
        url = f'{self.base_url}/api/addresses/'
        params = {'search': search} if search else {}
        response = requests.get(url, headers=self.headers, params=params)
        return response.json()
    
    def get_address(self, address_id):
        url = f'{self.base_url}/api/addresses/{address_id}/'
        response = requests.get(url, headers=self.headers)
        return response.json()
    
    def create_address(self, address_data):
        url = f'{self.base_url}/api/addresses/'
        response = requests.post(url, headers=self.headers, json=address_data)
        return response.json()
    
    def update_address(self, address_id, address_data):
        url = f'{self.base_url}/api/addresses/{address_id}/'
        response = requests.patch(url, headers=self.headers, json=address_data)
        return response.json()
    
    def delete_address(self, address_id):
        url = f'{self.base_url}/api/addresses/{address_id}/'
        response = requests.delete(url, headers=self.headers)
        return response.status_code == 204

# Usage
api = AddressAPI('http://localhost:8000', 'your_jwt_token')

# Get all addresses
addresses = api.get_all_addresses()

# Create address
new_address = api.create_address({
    'title': 'Home',
    'address_line_1': '123 Main Street',
    'city': 'Mumbai',
    'state': 'Maharashtra',
    'country': 'India',
    'postal_code': '400001',
    'is_default': True
})

# Set default
api.update_address(2, {'is_default': True})
```

---

### Flutter/Dart Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressService {
  final String baseUrl;
  final String token;

  AddressService(this.baseUrl, this.token);

  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // Get all addresses
  Future<List<Map<String, dynamic>>> getAllAddresses({String? search}) async {
    String url = '$baseUrl/api/addresses/';
    if (search != null) {
      url += '?search=${Uri.encodeComponent(search)}';
    }
    
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load addresses');
  }

  // Get address by ID
  Future<Map<String, dynamic>> getAddress(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/addresses/$id/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load address');
  }

  // Create address
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/addresses/'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create address');
  }

  // Update address
  Future<Map<String, dynamic>> updateAddress(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/addresses/$id/'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update address');
  }

  // Delete address
  Future<bool> deleteAddress(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/addresses/$id/'),
      headers: headers,
    );
    return response.statusCode == 204;
  }

  // Set default address
  Future<void> setDefaultAddress(int id) async {
    await updateAddress(id, {'is_default': true});
  }
}

// Usage
final addressService = AddressService('http://localhost:8000', 'your_token');

// Get all addresses
final addresses = await addressService.getAllAddresses();

// Create address
final newAddress = await addressService.createAddress({
  'title': 'Home',
  'address_line_1': '123 Main Street',
  'city': 'Mumbai',
  'state': 'Maharashtra',
  'country': 'India',
  'postal_code': '400001',
  'is_default': true,
});
```

---

## Best Practices

### 1. Coordinate Handling

- **Always provide both coordinates together** - Never send only latitude or only longitude
- **Validate coordinates before sending** - Check ranges on frontend before API call
- **Handle coordinate errors gracefully** - Show user-friendly error messages
- **Update coordinates when address changes** - Re-geocode if address text changes

### 2. Default Address Management

- **Show default badge** - Display which address is default
- **Allow easy default switching** - Provide one-click option to set default
- **Auto-select default in checkout** - Use default address as initial selection
- **Handle default removal** - If default is deleted, auto-select another

### 3. Error Handling

- **Validate on frontend first** - Check required fields before API call
- **Show specific error messages** - Display field-level errors
- **Handle network errors** - Retry on network failure
- **Handle 404 gracefully** - Address may have been deleted

### 4. Performance

- **Cache address list** - Don't refetch unnecessarily
- **Use search for filtering** - Use search parameter instead of filtering client-side
- **Lazy load coordinates** - Only fetch coordinates when needed
- **Batch updates** - Update multiple fields in one request

### 5. Security

- **Never expose other users' addresses** - Backend filters by user
- **Validate user ownership** - Backend checks address belongs to user
- **Use HTTPS** - Always use secure connections
- **Store tokens securely** - Never expose JWT tokens

---

## Integration Notes

### Checkout Integration

- Load addresses on checkout page load
- Auto-select default address
- Allow address selection/creation
- Update address coordinates from GPS
- Use selected address in order creation

### Profile Integration

- Show all addresses in profile
- Allow CRUD operations
- Show default badge
- Allow setting default
- Show address usage (order count)

### Order History Integration

- Display delivery address in order details
- Show address on order tracking
- Allow reusing address from previous orders

---

## Summary

The Address API provides a complete solution for managing user delivery addresses with:

- ✅ Full CRUD operations
- ✅ Default address management
- ✅ GPS coordinate support and validation
- ✅ Search functionality
- ✅ Automatic ordering
- ✅ User-specific filtering
- ✅ Soft delete support
- ✅ Comprehensive error handling

All endpoints require authentication and automatically filter addresses by the authenticated user, ensuring data security and privacy.

