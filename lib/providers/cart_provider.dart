import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../services/api_service.dart';

/// Cart Provider
/// 
/// Manages shopping cart state across the application
class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

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
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error adding to cart: $_error');
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
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error updating cart item: $_error');
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
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ Error removing from cart: $_error');
      notifyListeners();
      return false;
    }
  }

  /// Clear cart
  void clearCart() {
    _cart = null;
    _currentVendorId = null;
    _error = null;
    notifyListeners();
    debugPrint('🧹 Cart cleared');
  }

  /// Refresh cart
  Future<void> refreshCart() async {
    if (_currentVendorId != null) {
      await loadCart(_currentVendorId!);
    }
  }
}

