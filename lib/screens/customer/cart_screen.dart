import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'checkout_screen.dart';

/// Cart Screen
/// 
/// Displays user's shopping cart with items and checkout options
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart when screen loads
    // Try to load from existing cart first, then refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = context.read<CartProvider>();
      // Try loading from existing cart first (useful after login)
      cartProvider.loadCartFromExisting().then((_) {
        // If that didn't work, try refresh
        if (cartProvider.currentVendorId == null) {
          cartProvider.refreshCart();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: AppTheme.bgWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!cartProvider.hasItems) {
            return _buildEmptyCart();
          }

          final cart = cartProvider.cart!;

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cartProvider.refreshCart(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
                      vertical: 16,
                    ),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(item, cartProvider, isDesktop, isTablet);
                    },
                  ),
                ),
              ),

              // Cart Summary
              _buildCartSummary(cart, isDesktop, isTablet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add items from restaurants to get started',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Browse Restaurants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item, CartProvider cartProvider, bool isDesktop, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: isDesktop ? 100 : 80,
                height: isDesktop ? 100 : 80,
                child: ImageUtils.buildNetworkImage(
                  imageUrl: item.product.image ?? '',
                  width: isDesktop ? 100 : 80,
                  height: isDesktop ? 100 : 80,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: AppTheme.bgGray,
                    child: const Icon(Icons.fastfood, size: 40, color: AppTheme.textMuted),
                  ),
                  errorWidget: Container(
                    color: AppTheme.bgGray,
                    child: const Icon(Icons.fastfood, size: 40, color: AppTheme.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.unitPrice.toStringAsFixed(0)} each',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgLightGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Decrease Button
                            InkWell(
                              onTap: item.quantity > 1
                                  ? () async {
                                      final success = await cartProvider.updateCartItem(
                                        itemId: item.id,
                                        quantity: item.quantity - 1,
                                      );
                                      
                                      if (!success && mounted) {
                                        final errorMsg = cartProvider.error ?? 'Failed to update quantity';
                                        if (errorMsg.contains('log in')) {
                                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                                          scaffoldMessenger.clearSnackBars();
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text(errorMsg),
                                              backgroundColor: AppTheme.error,
                                              duration: const Duration(seconds: 3),
                                              behavior: SnackBarBehavior.floating,
                                              action: SnackBarAction(
                                                label: 'LOGIN',
                                                textColor: Colors.white,
                                                onPressed: () {
                                                  scaffoldMessenger.hideCurrentSnackBar();
                                                  Navigator.of(context).pushReplacementNamed('/login');
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: item.quantity > 1
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ),
                            // Quantity Manual Input
                            Container(
                              width: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: TextField(
                                controller: TextEditingController(text: item.quantity.toString())
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: item.quantity.toString().length),
                                  ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  isDense: true,
                                ),
                                onSubmitted: (value) async {
                                  final newQuantity = int.tryParse(value);
                                  if (newQuantity != null && newQuantity > 0 && newQuantity != item.quantity) {
                                    final success = await cartProvider.updateCartItem(
                                      itemId: item.id,
                                      quantity: newQuantity,
                                    );
                                    
                                    if (!success && mounted) {
                                      final errorMsg = cartProvider.error ?? 'Failed to update quantity';
                                      if (errorMsg.contains('log in')) {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        scaffoldMessenger.clearSnackBars();
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(errorMsg),
                                            backgroundColor: AppTheme.error,
                                            duration: const Duration(seconds: 3),
                                            behavior: SnackBarBehavior.floating,
                                            action: SnackBarAction(
                                              label: 'LOGIN',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                scaffoldMessenger.hideCurrentSnackBar();
                                                Navigator.of(context).pushReplacementNamed('/login');
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                            // Increase Button
                            InkWell(
                              onTap: () async {
                                final success = await cartProvider.updateCartItem(
                                  itemId: item.id,
                                  quantity: item.quantity + 1,
                                );
                                
                                if (!success && mounted) {
                                  final errorMsg = cartProvider.error ?? 'Failed to update quantity';
                                  if (errorMsg.contains('log in')) {
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    scaffoldMessenger.clearSnackBars();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(errorMsg),
                                        backgroundColor: AppTheme.error,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                          label: 'LOGIN',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            scaffoldMessenger.hideCurrentSnackBar();
                                            Navigator.of(context).pushReplacementNamed('/login');
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Total Price
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Item'),
                    content: const Text('Are you sure you want to remove this item from cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final success = await cartProvider.removeFromCart(item.id);
                  
                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item removed from cart'),
                          backgroundColor: AppTheme.primaryGreen,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else {
                      // Show error message from provider
                      final errorMsg = cartProvider.error ?? 'Failed to remove item';
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.clearSnackBars(); // Clear any existing snackbars
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: AppTheme.error,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          action: errorMsg.contains('log in')
                              ? SnackBarAction(
                                  label: 'LOGIN',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    scaffoldMessenger.hideCurrentSnackBar();
                                    // Navigate to login screen
                                    Navigator.of(context).pushReplacementNamed('/login');
                                  },
                                )
                              : null,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(dynamic cart, bool isDesktop, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtotal
              _buildSummaryRow('Subtotal', cart.subtotal),
              const SizedBox(height: 8),
              // Delivery Fee
              _buildSummaryRow('Delivery Fee', cart.deliveryFee),
              const SizedBox(height: 8),
              // Tax
              _buildSummaryRow('Tax', cart.tax),
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
              const SizedBox(height: 16),
              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Check authentication
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (!authProvider.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login to proceed to checkout'),
                          backgroundColor: AppTheme.error,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    // Navigate to checkout
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CheckoutScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isDesktop ? 18 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

