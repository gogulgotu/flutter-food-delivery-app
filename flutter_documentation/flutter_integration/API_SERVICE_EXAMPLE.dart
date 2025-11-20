// API Service Example for Flutter
// This file demonstrates how to create API services for the Hotel Management System

import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/models/user.dart';
import '../core/models/order.dart';
import '../core/models/product.dart';
import '../core/models/vendor.dart';
import '../core/models/address.dart';
import '../core/models/cart.dart';

/// Base API Service class
abstract class BaseApiService {
  final ApiClient apiClient = ApiClient();
  
  // Helper method to handle paginated responses
  List<T> parsePaginatedResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.data is Map && response.data.containsKey('results')) {
      final List<dynamic> results = response.data['results'];
      return results.map((json) => fromJson(json as Map<String, dynamic>)).toList();
    } else if (response.data is List) {
      return (response.data as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

/// Authentication Service
class AuthService extends BaseApiService {
  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/register/',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Send OTP to mobile number
  Future<Map<String, dynamic>> sendOTP(String mobileNumber) async {
    try {
      final response = await apiClient.post(
        '/auth/send-otp/',
        data: {
          'mobile_number': mobileNumber,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verify OTP and get tokens
  Future<Map<String, dynamic>> verifyOTP({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/verify-otp/',
        data: {
          'mobile_number': mobileNumber,
          'otp': otp,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Refresh access token
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.post(
        '/auth/token/refresh/',
        data: {
          'refresh': refreshToken,
        },
      );
      return response.data['access'];
    } catch (e) {
      rethrow;
    }
  }
}

/// User Service
class UserService extends BaseApiService {
  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await apiClient.get('/users/profile/');
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update user profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiClient.patch(
        '/users/profile/update/',
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Upload profile picture
  Future<User> uploadProfilePicture(String imagePath) async {
    try {
      final response = await apiClient.uploadFile(
        '/profile/upload-picture/',
        imagePath,
        fileKey: 'profile_picture',
      );
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Address Service
class AddressService extends BaseApiService {
  /// Get all user addresses
  Future<List<Address>> getAddresses() async {
    try {
      final response = await apiClient.get('/addresses/');
      return parsePaginatedResponse<Address>(
        response,
        (json) => Address.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Create new address
  Future<Address> createAddress({
    required String title,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await apiClient.post(
        '/addresses/',
        data: {
          'title': title,
          'address_line_1': addressLine1,
          if (addressLine2 != null) 'address_line_2': addressLine2,
          'city': city,
          'state': state,
          'country': country,
          'postal_code': postalCode,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'is_default': isDefault,
        },
      );
      return Address.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update address
  Future<Address> updateAddress(
    int addressId, {
    String? title,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
  }) async {
    try {
      final response = await apiClient.patch(
        '/addresses/$addressId/',
        data: {
          if (title != null) 'title': title,
          if (addressLine1 != null) 'address_line_1': addressLine1,
          if (addressLine2 != null) 'address_line_2': addressLine2,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (postalCode != null) 'postal_code': postalCode,
        },
      );
      return Address.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Delete address
  Future<void> deleteAddress(int addressId) async {
    try {
      await apiClient.delete('/addresses/$addressId/');
    } catch (e) {
      rethrow;
    }
  }
}

/// Vendor Service
class VendorService extends BaseApiService {
  /// Get list of vendors
  Future<List<Vendor>> getVendors({
    String? category,
    String? search,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await apiClient.get(
        '/vendors/',
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null) 'search': search,
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );
      return parsePaginatedResponse<Vendor>(
        response,
        (json) => Vendor.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get vendor details
  Future<Vendor> getVendorDetails(String slug) async {
    try {
      final response = await apiClient.get('/vendors/$slug/');
      return Vendor.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get vendor categories
  Future<List<VendorCategory>> getCategories() async {
    try {
      final response = await apiClient.get('/vendor-categories/');
      return parsePaginatedResponse<VendorCategory>(
        response,
        (json) => VendorCategory.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Product Service
class ProductService extends BaseApiService {
  /// Get list of products
  Future<List<Product>> getProducts({
    String? vendor,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? isAvailable,
    int? page,
  }) async {
    try {
      final response = await apiClient.get(
        '/products/',
        queryParameters: {
          if (vendor != null) 'vendor': vendor,
          if (category != null) 'category': category,
          if (search != null) 'search': search,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (isAvailable != null) 'is_available': isAvailable,
          if (page != null) 'page': page,
        },
      );
      return parsePaginatedResponse<Product>(
        response,
        (json) => Product.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get product details
  Future<Product> getProductDetails(String slug) async {
    try {
      final response = await apiClient.get('/products/$slug/');
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Cart Service
class CartService extends BaseApiService {
  /// Get user cart
  Future<Cart> getCart(String vendorId) async {
    try {
      final response = await apiClient.get(
        '/cart/',
        queryParameters: {'vendor': vendorId},
      );
      return Cart.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Add item to cart
  Future<CartItem> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
  }) async {
    try {
      final response = await apiClient.post(
        '/cart/items/',
        data: {
          'product': productId,
          'quantity': quantity,
          if (variantId != null) 'variant': variantId,
        },
      );
      return CartItem.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update cart item
  Future<CartItem> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    try {
      final response = await apiClient.patch(
        '/cart/items/$itemId/',
        data: {'quantity': quantity},
      );
      return CartItem.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Remove item from cart
  Future<void> removeFromCart(int itemId) async {
    try {
      await apiClient.delete('/cart/items/$itemId/delete/');
    } catch (e) {
      rethrow;
    }
  }
}

/// Order Service
class OrderService extends BaseApiService {
  /// Get user orders
  Future<List<Order>> getOrders({
    String? status,
    int? page,
  }) async {
    try {
      final response = await apiClient.get(
        '/orders/',
        queryParameters: {
          if (status != null) 'status': status,
          if (page != null) 'page': page,
        },
      );
      return parsePaginatedResponse<Order>(
        response,
        (json) => Order.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Create new order
  Future<Order> createOrder({
    required String vendorId,
    required int deliveryAddressId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    required String paymentMethod,
    String? scheduledDeliveryTime,
    double? customerLatitude,
    double? customerLongitude,
  }) async {
    try {
      final response = await apiClient.post(
        '/orders/',
        data: {
          'vendor': vendorId,
          'delivery_address': deliveryAddressId,
          'items': items,
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'payment_status': 'pending',
          if (scheduledDeliveryTime != null)
            'scheduled_delivery_time': scheduledDeliveryTime,
          if (customerLatitude != null) 'customer_latitude': customerLatitude,
          if (customerLongitude != null) 'customer_longitude': customerLongitude,
        },
      );
      return Order.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get order details
  Future<Order> getOrderDetails(String orderId) async {
    try {
      final response = await apiClient.get('/orders/$orderId/');
      return Order.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cancel order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await apiClient.post(
        '/orders/$orderId/cancel/',
        data: {
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Payment Service
class PaymentService extends BaseApiService {
  /// Create Paytm payment order
  Future<Map<String, dynamic>> createPaytmOrder(String orderId) async {
    try {
      final response = await apiClient.post(
        '/payments/paytm/create-order/',
        data: {'order_id': orderId},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verify Paytm payment
  Future<Map<String, dynamic>> verifyPaytmPayment(
    Map<String, dynamic> paymentParams,
  ) async {
    try {
      // Convert to form data for Paytm callback
      final formData = FormData.fromMap(
        paymentParams.map((key, value) => MapEntry(key, value.toString())),
      );
      
      final response = await apiClient.dio.post(
        '/payments/paytm/verify/',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get payment history
  Future<List<Payment>> getPayments() async {
    try {
      final response = await apiClient.get('/payments/');
      return parsePaginatedResponse<Payment>(
        response,
        (json) => Payment.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Notification Service
class NotificationService extends BaseApiService {
  /// Get notifications
  Future<List<Notification>> getNotifications() async {
    try {
      final response = await apiClient.get('/notifications/');
      return parsePaginatedResponse<Notification>(
        response,
        (json) => Notification.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await apiClient.patch(
        '/notifications/$notificationId/',
        data: {'is_read': true},
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await apiClient.post('/notifications/mark-all-read/');
    } catch (e) {
      rethrow;
    }
  }
}

/// Delivery Service (for delivery persons)
class DeliveryService extends BaseApiService {
  /// Get delivery dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await apiClient.get('/delivery/dashboard/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Toggle online status
  Future<Map<String, dynamic>> toggleOnline(bool isOnline) async {
    try {
      final response = await apiClient.post(
        '/delivery/toggle-online/',
        data: {'is_online': isOnline},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get available orders
  Future<List<Order>> getAvailableOrders() async {
    try {
      final response = await apiClient.get('/orders/available/');
      return parsePaginatedResponse<Order>(
        response,
        (json) => Order.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Accept order
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      final response = await apiClient.post(
        '/delivery/orders/$orderId/accept/',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

/// Usage Example:
/// 
/// ```dart
/// final authService = AuthService();
/// final userService = UserService();
/// final orderService = OrderService();
/// 
/// // Login
/// final loginResponse = await authService.login(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// 
/// // Get user profile
/// final user = await userService.getProfile();
/// 
/// // Get orders
/// final orders = await orderService.getOrders();
/// ```

