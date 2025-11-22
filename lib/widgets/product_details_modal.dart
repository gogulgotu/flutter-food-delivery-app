import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/customer/cart_screen.dart';
import 'package:provider/provider.dart';

/// Product Details Modal
/// 
/// Displays detailed product information in a bottom sheet with add to cart functionality
class ProductDetailsModal extends StatefulWidget {
  final ProductModel product;
  final String vendorId;

  const ProductDetailsModal({
    super.key,
    required this.product,
    required this.vendorId,
  });

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal> {
  final ApiService _apiService = ApiService();
  ProductModel? _detailedProduct;
  bool _isLoading = true;
  bool _isAddingToCart = false; // Track if add to cart is in progress
  String? _error;
  int _quantity = 0; // Start with 0, button appears when quantity is selected
  String? _selectedVariantId;
  Map<String, dynamic>? _variants;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productData = await _apiService.getProductDetails(widget.product.slug);
      _detailedProduct = ProductModel.fromJson(productData);
      
      // Extract variants if available
      if (productData['variants'] != null && productData['variants'] is List) {
        final variantsList = productData['variants'] as List;
        if (variantsList.isNotEmpty) {
          _variants = productData['variants'][0] as Map<String, dynamic>?;
          if (_variants != null && 
              _variants!['options'] != null && 
              (_variants!['options'] as List).isNotEmpty) {
            _selectedVariantId = (_variants!['options'] as List)[0]['id'] as String?;
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    // Prevent duplicate calls
    if (_isAddingToCart) {
      debugPrint('⚠️ Add to cart already in progress, ignoring duplicate call');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    try {
      debugPrint('Adding to cart: product=${_detailedProduct?.id ?? widget.product.id}, quantity=$_quantity');
      
      final success = await cartProvider.addToCart(
        productId: _detailedProduct?.id ?? widget.product.id,
        quantity: _quantity,
        variantId: _selectedVariantId,
        vendorId: widget.vendorId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_detailedProduct?.name ?? widget.product.name} ($_quantity ${_quantity == 1 ? "item" : "items"}) added to cart'
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // Close modal first
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
              },
            ),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate item was added
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProvider.error ?? 'Failed to add to cart'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _detailedProduct ?? widget.product;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorView()
                  : Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 32 : 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                _buildProductImage(product),
                                
                                const SizedBox(height: 16),
                                
                                // Product Name and Price
                                _buildProductHeader(product),
                                
                                const SizedBox(height: 16),
                                
                                // Description
                                if (product.description != null) ...[
                                  _buildDescription(product),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Variants (if available)
                                if (_variants != null) ...[
                                  _buildVariants(),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Quantity Selector
                                _buildQuantitySelector(),
                                
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        
                        // Add to Cart Button
                        _buildAddToCartButton(product),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildProductImage(ProductModel product) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.bgGray,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ImageUtils.buildNetworkImage(
          imageUrl: product.image,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorWidget: Container(
            color: AppTheme.bgGray,
            child: const Icon(
              Icons.fastfood,
              size: 64,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Availability Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: product.isAvailable 
                    ? AppTheme.primaryGreen 
                    : AppTheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.isAvailable ? 'Available' : 'Unavailable',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (product.hasDiscount) ...[
              Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '₹${product.effectivePrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            if (product.hasDiscount) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${((1 - product.effectivePrice / product.price) * 100).toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description!,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVariants() {
    if (_variants == null || _variants!['options'] == null) {
      return const SizedBox.shrink();
    }

    final options = _variants!['options'] as List;
    final variantName = _variants!['name'] as String? ?? 'Options';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          variantName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map<Widget>((option) {
            final optionId = option['id'] as String?;
            final optionName = option['name'] as String? ?? '';
            final optionPrice = (option['price'] as num?)?.toDouble() ?? 0.0;
            final isSelected = _selectedVariantId == optionId;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedVariantId = optionId;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.bgWhite,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.bgGray,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      optionName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (optionPrice > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+₹${optionPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.primaryGreen,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: isDesktop ? 20 : isTablet ? 19 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _quantity > 0 
                    ? AppTheme.primaryGreen.withOpacity(0.1)
                    : AppTheme.bgLightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _quantity > 0 ? AppTheme.primaryGreen : AppTheme.bgGray, 
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Decrease Button
                  InkWell(
                    onTap: _quantity > 0
                        ? () {
                            setState(() {
                              _quantity--;
                            });
                          }
                        : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
                      child: Icon(
                        Icons.remove,
                        color: _quantity > 0 
                            ? AppTheme.primaryGreen 
                            : AppTheme.textMuted,
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                  ),
                  // Quantity Manual Input
                  Container(
                    width: isDesktop ? 70 : isTablet ? 65 : 60,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 4,
                    ),
                    child: TextField(
                      controller: TextEditingController(text: _quantity.toString())
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _quantity.toString().length),
                        ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : isTablet ? 19 : 18,
                        fontWeight: FontWeight.bold,
                        color: _quantity > 0 ? AppTheme.primaryGreen : AppTheme.textSecondary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        final newQuantity = int.tryParse(value);
                        if (newQuantity != null && newQuantity >= 0) {
                          setState(() {
                            _quantity = newQuantity;
                          });
                        } else {
                          // Reset to previous value if invalid
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  // Increase Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
                      child: Icon(
                        Icons.add,
                        color: AppTheme.primaryGreen,
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_quantity > 0) ...[
              const SizedBox(width: 16),
              // Show total price for selected quantity
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSectionGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: ₹${((_detailedProduct ?? widget.product).effectivePrice * _quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(ProductModel product) {
    final isAvailable = product.isAvailable;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    // Calculate total price
    final totalPrice = product.effectivePrice * _quantity;
    
    // Only show button when quantity is selected (quantity > 0)
    if (_quantity == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : isTablet ? 18 : 16),
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isAvailable && !_isAddingToCart) ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 18 : isTablet ? 17 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppTheme.bgGray,
            ),
            child: _isAddingToCart
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Adding to Cart...',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isAvailable 
                            ? 'Add $_quantity ${_quantity == 1 ? "Item" : "Items"} to Cart - ₹${totalPrice.toStringAsFixed(0)}'
                            : 'Currently Unavailable',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load product details',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

