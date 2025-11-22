import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../services/api_service.dart';

/// Cart Provider
/// 
/// Manages shopping cart state across the application
class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const String _vendorIdKey = 'last_cart_vendor_id';

  CartModel? _cart;
  bool _isLoading = false;
  String? _error;
  String? _currentVendorId;

  // Getters
  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.itemCount ?? 0;
  bool get hasItems => _cart != null && _cart!.isNotEmpty;
  String? get currentVendorId => _currentVendorId;

  /// Load cart for a specific vendor
  Future<void> loadCart(String vendorId) async {
    _isLoading = true;
    _error = null;
    _currentVendorId = vendorId;
    notifyListeners();

    try {
      debugPrint('🛒 Loading cart for vendor: $vendorId');
      final data = await _apiService.getCart(vendorId);
      debugPrint('🛒 Cart data received: $data');
      
      // Verify the cart vendor matches the requested vendor before accepting it
      final cartVendorId = data['vendor_id'] as String? ?? data['vendor'] as String?;
      final hasVendorMismatch = cartVendorId != null && cartVendorId != vendorId;
      
      if (hasVendorMismatch) {
        debugPrint('⚠️ WARNING: Cart vendor mismatch!');
        debugPrint('   Requested vendor: $vendorId');
        debugPrint('   Received vendor: $cartVendorId');
        debugPrint('   This may indicate a backend issue or the user has items in multiple carts.');
        
        // If we already have a cart for the requested vendor, don't overwrite it with wrong vendor's cart
        if (_cart != null && _cart!.vendor.id == vendorId && _cart!.items.isNotEmpty) {
          debugPrint('⚠️ Keeping existing cart for vendor $vendorId (${_cart!.itemCount} items)');
          debugPrint('   Backend returned wrong vendor\'s cart - not overwriting existing cart.');
          _currentVendorId = vendorId;
          // Don't overwrite _cart with wrong vendor's data
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        // If backend returned wrong vendor and we don't have a cart for requested vendor,
        // still don't accept wrong vendor's cart - keep existing cart or leave empty
        if (_cart != null && _cart!.vendor.id == vendorId) {
          debugPrint('⚠️ Backend returned wrong vendor\'s cart. Keeping existing cart for vendor $vendorId.');
          _currentVendorId = vendorId;
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        // Don't update _currentVendorId if there's a mismatch
        // Keep the requested vendor ID instead
      }
      
      // Only parse and set cart if we should accept this data
      // (either correct vendor or no existing cart for requested vendor)
      if (!hasVendorMismatch || _cart == null || _cart!.vendor.id != vendorId) {
        _cart = CartModel.fromJson(data);
        _error = null;
      }
      
      // Update vendor ID from the loaded cart ONLY if it matches what we requested
      if (_cart != null && _cart!.vendor.id.isNotEmpty) {
        if (_cart!.vendor.id == vendorId) {
          _currentVendorId = _cart!.vendor.id;
          // Store vendor ID persistently for future sessions
          await _saveVendorId(_currentVendorId!);
        } else {
          debugPrint('⚠️ Keeping requested vendor ID ($vendorId) instead of cart vendor (${_cart!.vendor.id})');
          _currentVendorId = vendorId; // Keep the requested vendor ID
        }
      }
      
      debugPrint('✅ Cart loaded: ${_cart!.itemCount} items (vendor: ${_cart!.vendor.id})');
    } catch (e, stackTrace) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error loading cart: $_error');
      debugPrint('❌ Stack trace: $stackTrace');
      // Don't clear cart on error, keep existing data
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to cart
  Future<bool> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
    String? vendorId,
  }) async {
    try {
      debugPrint('➕ Adding to cart: product=$productId, quantity=$quantity, vendor=$vendorId');
      
      // Ensure we have a vendor ID
      String? targetVendorId = vendorId ?? _currentVendorId;
      
      if (targetVendorId == null || targetVendorId.isEmpty) {
        debugPrint('❌ Cannot add to cart: No vendor ID provided');
        _error = 'Vendor information is missing. Please try again.';
        notifyListeners();
        return false;
      }

      // Make the API call to add item
      final response = await _apiService.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );

      debugPrint('✅ Add to cart API response: $response');
      
      // Extract vendor_id from the response (the item was added to this vendor's cart)
      String? responseVendorId;
      if (response is Map<String, dynamic>) {
        responseVendorId = response['vendor_id'] as String?;
        if (responseVendorId == null || responseVendorId.isEmpty) {
          // Try alternative field names
          responseVendorId = response['vendor'] as String?;
        }
        debugPrint('📦 Vendor ID from addToCart response: $responseVendorId');
      }
      
      // Use vendor ID from response if available, otherwise use the provided one
      final actualVendorId = responseVendorId ?? targetVendorId;
      if (actualVendorId == null || actualVendorId.isEmpty) {
        debugPrint('❌ Cannot reload cart: No vendor ID available');
        _error = 'Unable to refresh cart. Please check your cart manually.';
        notifyListeners();
        return true; // Still return true since the API call succeeded
      }
      
      // Update current vendor ID to match the vendor from the response
      if (responseVendorId != null && responseVendorId != _currentVendorId) {
        debugPrint('🔄 Updating current vendor ID from $targetVendorId to $responseVendorId');
        _currentVendorId = responseVendorId;
        await _saveVendorId(responseVendorId);
      }
      
      debugPrint('🔄 Reloading cart for vendor: $actualVendorId');
      
      // Wait a brief moment to ensure the backend has processed the request
      await Future.delayed(const Duration(milliseconds: 500));

      // Extract cart_id from addToCart response - we'll need this if vendor mismatch occurs
      String? responseCartId;
      Map<String, dynamic>? cartItemData;
      if (response is Map<String, dynamic>) {
        responseCartId = response['cart_id'] as String?;
        cartItemData = response; // Store the full response for constructing cart
      }

      // Reload cart using the vendor ID from the response
      await loadCart(actualVendorId);

      // Verify the cart vendor matches what we expect
      bool vendorMismatch = false;
      if (_cart != null) {
        final cartVendorId = _cart!.vendor.id;
        if (cartVendorId != actualVendorId) {
          vendorMismatch = true;
          debugPrint('⚠️ Cart vendor mismatch detected!');
          debugPrint('   Expected vendor: $actualVendorId');
          debugPrint('   Received vendor: $cartVendorId');
          debugPrint('   Cart ID from addToCart: $responseCartId');
          debugPrint('   Cart ID from getCart: ${_cart!.id}');
          debugPrint('   This indicates the backend returned the wrong cart.');
        }
      }

      // If vendor mismatch, construct a cart from addToCart response
      if (vendorMismatch && cartItemData != null && responseCartId != null) {
        debugPrint('🔄 Vendor mismatch: Constructing cart from addToCart response...');
        
        try {
          // Extract vendor info from response
          final vendorName = cartItemData['vendor_name'] as String? ?? 'Restaurant';
          
          // Create a cart item from the addToCart response
          final cartItem = CartItemModel.fromJson(cartItemData);
          
          // Construct a minimal cart from the response
          // Use the cart_id and vendor_id from the addToCart response
          final cartData = <String, dynamic>{
            'id': responseCartId,
            'vendor': actualVendorId,
            'vendor_id': actualVendorId,
            'vendor_name': vendorName,
            'items': [cartItemData], // The item that was just added
            'subtotal': cartItemData['total_price'] ?? 0.0,
            'delivery_fee': 0.0,
            'tax': 0.0,
            'total': cartItemData['total_price'] ?? 0.0,
          };
          
          // Create cart model from constructed data
          _cart = CartModel.fromJson(cartData);
          _currentVendorId = actualVendorId;
          await _saveVendorId(actualVendorId);
          
          debugPrint('✅ Constructed cart from addToCart response');
          debugPrint('   Cart ID: $responseCartId');
          debugPrint('   Vendor: $actualVendorId');
          debugPrint('   Items: 1');
          
          notifyListeners();
          return true;
        } catch (e, stackTrace) {
          debugPrint('❌ Error constructing cart from response: $e');
          debugPrint('   Stack trace: $stackTrace');
          
          // Fall back to retry
          await Future.delayed(const Duration(milliseconds: 1500));
          await loadCart(actualVendorId);
          
          if (_cart != null && _cart!.vendor.id == actualVendorId) {
            debugPrint('✅ Vendor match after retry!');
          } else {
            debugPrint('❌ Still getting wrong vendor after retry.');
            return true; // Still return true since add succeeded
          }
        }
      }

      // Verify the item was actually added
      if (_cart != null && _cart!.items.isNotEmpty) {
        final itemExists = _cart!.items.any((item) => item.product.id == productId);
        if (itemExists) {
          debugPrint('✅ Item added to cart successfully and verified');
          return true;
        } else {
          debugPrint('⚠️ Cart reloaded but item not found. Item count: ${_cart!.itemCount}');
          debugPrint('⚠️ Cart vendor: ${_cart!.vendor.id}, Expected vendor: $actualVendorId');
          
          if (vendorMismatch) {
            debugPrint('⚠️ Backend returned wrong vendor\'s cart. Item was added but not visible.');
            debugPrint('⚠️ The item exists in vendor $actualVendorId\'s cart, but backend shows vendor ${_cart!.vendor.id}\'s cart.');
          }
        }
      } else {
        debugPrint('⚠️ Cart is empty after reload. Item may not have been added.');
        debugPrint('⚠️ Requested vendor: $actualVendorId, Cart vendor: ${_cart?.vendor.id ?? "null"}');
        
        if (vendorMismatch) {
          debugPrint('⚠️ Backend returned wrong vendor\'s cart. Item was successfully added but cart shows different vendor.');
        }
      }

      debugPrint('✅ Item added to cart (cart may need refresh)');
      return true;
    } catch (e, stackTrace) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = errorMessage;
      
      debugPrint('❌ Error adding to cart: $_error');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Special handling for authentication errors
      if (errorMessage.contains('Authentication') || errorMessage.contains('credentials')) {
        debugPrint('❌ Authentication error adding to cart: $_error');
        debugPrint('⚠️ User may need to log in again');
        _error = 'Please log in to add items to cart';
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Update cart item quantity
  Future<bool> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    if (_cart == null) return false;

    try {
      debugPrint('🔄 Updating cart item: id=$itemId, quantity=$quantity');
      
      await _apiService.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );

      // Reload cart
      if (_currentVendorId != null) {
        await loadCart(_currentVendorId!);
      }

      debugPrint('✅ Cart item updated successfully');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = errorMessage;
      
      // Special handling for authentication errors
      if (errorMessage.contains('Authentication') || errorMessage.contains('credentials')) {
        debugPrint('❌ Authentication error updating cart: $_error');
        debugPrint('⚠️ User may need to log in again');
        _error = 'Please log in to manage your cart';
      } else {
        debugPrint('❌ Error updating cart item: $_error');
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(int itemId) async {
    if (_cart == null) return false;

    try {
      debugPrint('🗑️ Removing item from cart: id=$itemId');
      
      await _apiService.removeFromCart(itemId);

      // Reload cart
      if (_currentVendorId != null) {
        await loadCart(_currentVendorId!);
      }

      debugPrint('✅ Item removed from cart successfully');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = errorMessage;
      
      // Special handling for authentication errors
      if (errorMessage.contains('Authentication') || errorMessage.contains('credentials')) {
        debugPrint('❌ Authentication error removing from cart: $_error');
        debugPrint('⚠️ User may need to log in again');
        _error = 'Please log in to manage your cart';
      } else {
        debugPrint('❌ Error removing from cart: $_error');
      }
      
      notifyListeners();
      return false;
    }
  }

  /// Clear cart
  void clearCart() {
    _cart = null;
    _currentVendorId = null;
    _error = null;
    clearSavedVendorId(); // Also clear saved vendor ID
    notifyListeners();
    debugPrint('🧹 Cart cleared');
  }

  /// Refresh cart
  /// Tries to load cart using existing vendor ID from cart or stored vendor ID
  Future<void> refreshCart() async {
    // First, try to get vendor ID from existing cart
    String? vendorId = _currentVendorId;
    
    // If no vendor ID but we have a cart, extract vendor ID from cart
    if (vendorId == null && _cart != null) {
      vendorId = _cart!.vendor.id;
      _currentVendorId = vendorId;
      debugPrint('🛒 Using vendor ID from existing cart: $vendorId');
    }
    
    // If we have a vendor ID, load the cart
    if (vendorId != null) {
      await loadCart(vendorId);
    } else {
      debugPrint('⚠️ Cannot refresh cart: No vendor ID available');
      // Set loading to false in case it was set
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cart using vendor ID from existing cart or stored vendor ID
  /// This is useful when opening cart page directly after login
  Future<void> loadCartFromExisting() async {
    // If we have an existing cart, use its vendor ID
    if (_cart != null && _cart!.vendor.id.isNotEmpty) {
      final vendorId = _cart!.vendor.id;
      debugPrint('🛒 Loading cart from existing cart vendor: $vendorId');
      await loadCart(vendorId);
      return;
    }
    
    // If we have a stored vendor ID in memory, use that
    if (_currentVendorId != null) {
      debugPrint('🛒 Loading cart from stored vendor: $_currentVendorId');
      await loadCart(_currentVendorId!);
      return;
    }
    
    // Try to load vendor ID from persistent storage (for after login)
    final savedVendorId = await _loadVendorId();
    if (savedVendorId != null && savedVendorId.isNotEmpty) {
      debugPrint('🛒 Loading cart from saved vendor ID: $savedVendorId');
      _currentVendorId = savedVendorId;
      await loadCart(savedVendorId);
      return;
    }
    
    debugPrint('⚠️ Cannot load cart: No vendor ID available');
    _isLoading = false;
    notifyListeners();
  }

  /// Save vendor ID to persistent storage
  Future<void> _saveVendorId(String vendorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vendorIdKey, vendorId);
      debugPrint('💾 Saved vendor ID: $vendorId');
    } catch (e) {
      debugPrint('⚠️ Error saving vendor ID: $e');
    }
  }

  /// Load vendor ID from persistent storage
  Future<String?> _loadVendorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorId = prefs.getString(_vendorIdKey);
      debugPrint('📖 Loaded vendor ID from storage: $vendorId');
      return vendorId;
    } catch (e) {
      debugPrint('⚠️ Error loading vendor ID: $e');
      return null;
    }
  }

  /// Clear saved vendor ID (e.g., on logout)
  Future<void> clearSavedVendorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vendorIdKey);
      debugPrint('🗑️ Cleared saved vendor ID');
    } catch (e) {
      debugPrint('⚠️ Error clearing vendor ID: $e');
    }
  }
}

