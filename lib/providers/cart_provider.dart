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
      
      _cart = CartModel.fromJson(data);
      _error = null;
      
      // Update vendor ID from the loaded cart to ensure we have it for future refreshes
      if (_cart != null && _cart!.vendor.id.isNotEmpty) {
        _currentVendorId = _cart!.vendor.id;
        // Store vendor ID persistently for future sessions
        await _saveVendorId(_currentVendorId!);
      }
      
      debugPrint('✅ Cart loaded: ${_cart!.itemCount} items');
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
      debugPrint('➕ Adding to cart: product=$productId, quantity=$quantity');
      
      await _apiService.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );

      // Reload cart if we know the vendor
      if (vendorId != null) {
        await loadCart(vendorId);
      } else if (_currentVendorId != null) {
        await loadCart(_currentVendorId!);
      }

      debugPrint('✅ Item added to cart successfully');
      return true;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _error = errorMessage;
      
      // Special handling for authentication errors
      if (errorMessage.contains('Authentication') || errorMessage.contains('credentials')) {
        debugPrint('❌ Authentication error adding to cart: $_error');
        debugPrint('⚠️ User may need to log in again');
        _error = 'Please log in to add items to cart';
      } else {
        debugPrint('❌ Error adding to cart: $_error');
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

