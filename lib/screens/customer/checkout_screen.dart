import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/address_model.dart';
import '../../models/cart_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'checkout_step1_address_location.dart';
import 'checkout_step2_payment.dart';

/// Checkout Screen
/// 
/// Two-step checkout process:
/// Step 1: Delivery Address & Location
/// Step 2: Payment Method
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  AddressModel? _selectedAddress;
  double? _latitude;
  double? _longitude;
  String? _addressString;

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    // Check authentication
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // Check if cart has items
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (!cartProvider.hasItems) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your cart is empty'),
            backgroundColor: AppTheme.error,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Load user's location if available
    final user = authProvider.user;
    if (user?.latitude != null && user?.longitude != null) {
      setState(() {
        _latitude = user!.latitude;
        _longitude = user.longitude;
        _addressString = user.address;
      });
    }
  }

  void _onStep1Complete({
    required AddressModel address,
    required double latitude,
    required double longitude,
    String? addressString,
  }) {
    setState(() {
      _selectedAddress = address;
      _latitude = latitude;
      _longitude = longitude;
      _addressString = addressString;
      _currentStep = 1; // Move to Step 2
    });
  }

  void _onStep1Back() {
    // Allow going back to cart
    Navigator.of(context).pop();
  }

  void _onStep2Back() {
    setState(() {
      _currentStep = 0; // Go back to Step 1
    });
  }

  void _onOrderCreated(Map<String, dynamic> orderData) {
    // Order created successfully - handled in step 2
    // Navigation is handled in checkout_step2_payment.dart
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.bgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isLoading || !cartProvider.hasItems) {
            return const Center(child: CircularProgressIndicator());
          }

          final cart = cartProvider.cart!;

          if (isDesktop) {
            // Desktop layout with sidebar
            return Row(
              children: [
                // Main Content
                Expanded(
                  flex: 3,
                  child: _currentStep == 0
                      ? CheckoutStep1AddressLocation(
                          cart: cart,
                          selectedAddress: _selectedAddress,
                          latitude: _latitude,
                          longitude: _longitude,
                          addressString: _addressString,
                          onComplete: _onStep1Complete,
                          onBack: _onStep1Back,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        )
                      : CheckoutStep2Payment(
                          cart: cart,
                          address: _selectedAddress!,
                          latitude: _latitude!,
                          longitude: _longitude!,
                          onOrderCreated: _onOrderCreated,
                          onBack: _onStep2Back,
                          isTablet: isTablet,
                          isDesktop: isDesktop,
                        ),
                ),
                // Order Summary Sidebar
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: AppTheme.bgLightGray,
                    border: Border(
                      left: BorderSide(color: AppTheme.bgGray, width: 1),
                    ),
                  ),
                  child: _buildOrderSummary(cart, isDesktop),
                ),
              ],
            );
          } else {
            // Mobile/Tablet layout (no order summary overlay)
            return _currentStep == 0
                ? CheckoutStep1AddressLocation(
                    cart: cart,
                    selectedAddress: _selectedAddress,
                    latitude: _latitude,
                    longitude: _longitude,
                    addressString: _addressString,
                    onComplete: _onStep1Complete,
                    onBack: _onStep1Back,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  )
                : CheckoutStep2Payment(
                    cart: cart,
                    address: _selectedAddress!,
                    latitude: _latitude!,
                    longitude: _longitude!,
                    onOrderCreated: _onOrderCreated,
                    onBack: _onStep2Back,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  );
          }
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartModel cart, bool isDesktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildOrderSummaryContent(cart, isDesktop),
      ],
    );
  }

  Widget _buildOrderSummaryContent(CartModel cart, bool isDesktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cart Items List
        ...cart.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImageUtils.buildNetworkImage(
                      imageUrl: item.product.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.bgGray,
                        child: const Icon(Icons.fastfood, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            )),
        if (cart.items.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${cart.items.length - 3} more item${cart.items.length - 3 > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const Divider(height: 24),
        // Summary
        _buildSummaryRow('Subtotal', cart.subtotal, isDesktop),
        const SizedBox(height: 8),
        _buildSummaryRow('Delivery Fee', cart.deliveryFee, isDesktop),
        const SizedBox(height: 8),
        _buildSummaryRow('Tax', cart.tax, isDesktop),
        const Divider(height: 24),
        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₹${cart.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isDesktop ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isDesktop ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}

